//
//  TKDeparturesProvider.swift
//  TripKit
//
//  Created by Adrian Schoenig on 22.09.17.
//

import Foundation

import RxSwift

@objc
public class TKDeparturesProvider: NSObject {
  private override init() {
    super.init()
  }
  
  enum InputError: Error {
    case missingField(String)
    case emptyField(String)
  }
  
  enum OutputError: Error {
    case noDataReturn
    case couldNotFetchRegions
    case stopSinceDeleted
  }

}

// MARK: - Departures.json for stops

extension TKDeparturesProvider {
  
  public class func fetchDepartures(forStopCodes stopCodes: [String], fromDate: Date = Date(), limit: Int = 10, in region: SVKRegion) -> Observable<API.Departures> {
    
    guard !stopCodes.isEmpty else {
      return Observable.error(InputError.missingField("stopCodes"))
    }
    
    let paras: [String: Any] = [
      "region": region.name,
      "embarkationStops": stopCodes,
      "timeStamp": fromDate.timeIntervalSince1970,
      "limit": limit,
      "config": TKSettings.defaultDictionary()
    ]
    
    return SVKServer.shared.rx
      .hit(.POST, path: "departures.json", parameters: paras, region: region)
      .map { _, _, data in
        guard let data = data else { throw OutputError.noDataReturn }
        let decoder = JSONDecoder()
        return try decoder.decode(API.Departures.self, from: data)
    }
  }
  
  public class func downloadDepartures(for stops: [StopLocation], fromDate: Date = Date(), limit: Int = 10) -> Observable<Bool> {
    
    let stopCodes = stops.map { $0.stopCode }
    
    return SVKServer.shared.rx
      .requireRegions()
      .flatMap { Void -> Observable<API.Departures> in
        guard let region = stops.first?.region else {
          throw OutputError.couldNotFetchRegions
        }
        return TKDeparturesProvider.fetchDepartures(forStopCodes: stopCodes, fromDate: fromDate, limit: limit, in: region)
      }
      .map { departures -> Bool in
        guard let context = stops.first?.managedObjectContext else {
          throw OutputError.stopSinceDeleted
        }
        var result = false
        context.performAndWait {
          result = TKDeparturesProvider.addDepartures(departures, to: stops)
        }
        return result
    }
  }
  
  private static func addDepartures(_ departures: API.Departures, to stops: [StopLocation]) -> Bool {
    
    guard let context = stops.first?.managedObjectContext else {
      return false
    }
    var addedStops = false
    
    // First, we process optional parent information
    let lookup = Dictionary(grouping: stops) { $0.stopCode }
    for parent in departures.parentStops ?? [] {
      if let existing = lookup[parent.code]?.first {
        addedStops = existing.update(from: parent) || addedStops
      } else {
        assertionFailure("Got a parent that we didn't ask for: \(parent)")
      }
    }
    
    // Next, we collect the existing stops to add content to
    let flattened = stops.flatMap {
      return [$0] + ($0.children ?? [])
    }
    let candidates = Dictionary(grouping: flattened) { $0.stopCode }
    
    // Now, we can add all the stops
    var addedCount = 0
    for embarkation in departures.embarkationStops {
      guard let stop = candidates[embarkation.stopCode]?.first else {
        assertionFailure("Got an embarkation but no stop to add it to: \(embarkation). Stops: \(candidates)")
        continue
      }
      
      for serviceModel in embarkation.services {
        addedCount += 1
        let service = Service(from: serviceModel, into: context)
        service.addVisits(StopVisits.self, from: serviceModel, at: stop)
      }
    }
    assert(addedCount > 0, "No embarkations in \(departures)")
    
    // Insert all the alerts, and make sure that the stops point
    // to them, too
    TKAPIToCoreDataConverter.updateOrAddAlerts(departures.alerts, in: context)
    departures.stops?.forEach {
      guard let hashCodes = $0.alertHashCodes else {
        return
      }
      lookup[$0.code]?.forEach { $0.alertHashCodes = hashCodes.map(NSNumber.init) }
    }
    
    return addedStops
  }
}

// MARK: - Departures.json for stop-to-stop

extension TKDeparturesProvider {
  
  @objc(queryParametersForDLSTable:fromDate:limit:)
  public class func queryParameters(for table: TKDLSTable, fromDate: Date, limit: Int) -> [String: Any] {
    return [
      "region": table.startRegion.name,
      "disembarkationRegion": table.endRegion.name,
      "timeStamp": fromDate.timeIntervalSince1970,
      "embarkationStops": [table.startStopCode],
      "disembarkationStops": [table.endStopCode],
      "limit": limit,
      "config": TKSettings.defaultDictionary()
    ]
  }
  
  public class func fetchDepartures(for table: TKDLSTable, fromDate: Date = Date(), limit: Int = 10) -> Observable<API.Departures> {
    
    let paras: [String: Any] = TKDeparturesProvider.queryParameters(for: table, fromDate: fromDate, limit: limit)
    
    return SVKServer.shared.rx
      .hit(.POST, path: "departures.json", parameters: paras, region: table.startRegion)
      .map { _, _, data in
        guard let data = data else { throw OutputError.noDataReturn }
        let decoder = JSONDecoder()
        return try decoder.decode(API.Departures.self, from: data)
    }
  }
  
  public class func downloadDepartures(for table: TKDLSTable, fromDate: Date = Date(), limit: Int = 10) -> Observable<Set<String>> {
    
    return SVKServer.shared.rx
      .requireRegions()
      .flatMap { Void -> Observable<API.Departures> in
        return TKDeparturesProvider.fetchDepartures(for: table, fromDate: fromDate, limit: limit)
      }
      .map { departures -> Set<String> in
        var result = Set<String>()
        let context = table.tripKitContext
        context.performAndWait {
          result = TKDeparturesProvider.addDepartures(departures, into: context)
        }
        return result
    }
  }
  
  private static func addDepartures(_ departures: API.Departures, into context: NSManagedObjectContext) -> Set<String> {
    
    // First, we make sure we have all the stops
    let stops = (departures.stops ?? [])
      .map { TKAPIToCoreDataConverter.insertNewStopLocation(from: $0, into: context) }
    
    // Next, we collect the existing stops to add content to
    let flattened = stops.flatMap {
      return [$0] + ($0.children ?? [])
    }
    let candidates = Dictionary(grouping: flattened) { $0.stopCode }
    
    // Now, we can add all the stops
    var pairIdentifieres = Set<String>()
    for embarkation in departures.embarkationStops {
      guard let startStop = candidates[embarkation.stopCode]?.first else {
        assertionFailure("Got an embarkation but no stop to add it to: \(embarkation). Stops: \(candidates)")
        continue
      }
      
      for serviceModel in embarkation.services {
        guard
          let endStopCode = serviceModel.endStopCode,
          let endStop = candidates[endStopCode]?.first else {
            assertionFailure("Got an disembarkation but no stop to add it to: \(embarkation). Stops: \(candidates)")
            continue
        }
        
        let service = Service(from: serviceModel, into: context)
        if let entry = service.addVisits(DLSEntry.self, from: serviceModel, at: startStop) {
          entry.pairIdentifier = "\(embarkation.stopCode)-\(endStopCode)"
          entry.endStop = endStop
          pairIdentifieres.insert(entry.pairIdentifier)
        }
      }
    }
    assert(!pairIdentifieres.isEmpty, "No embarkations in \(departures)")
    
    TKAPIToCoreDataConverter.updateOrAddAlerts(departures.alerts, in: context)
    
    return pairIdentifieres
  }
  
}
