//
//  TKDeparturesProvider.swift
//  TripKit
//
//  Created by Adrian Schönig on 01.11.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

#if canImport(CoreData)

import Foundation
import CoreData

@objc
public class TKDeparturesProvider: NSObject {
  
  /// Filter to apply to the results, treated as an "AND" condition.
  public struct Filter: Codable {
    public init(operatorID: String, routeID: String? = nil, directionID: String? = nil) {
      self.operatorID = operatorID
      self.routeID = routeID
      self.directionID = directionID
    }
    
    /// Operator identifier
    public let operatorID: String
    /// Route identifier for the provided operator
    public let routeID: String?
    /// Direction for the provided route, if provided, `routeID` is also required
    public let directionID: String?
  }
  
  public enum InputError: Error {
    case missingField(String)
    case emptyField(String)
  }
  
  public enum OutputError: Error {
    case couldNotFetchRegions
    case stopSinceDeleted
  }

  private override init() {
    super.init()
  }
}

// MARK: - Departures.json for stops

extension TKDeparturesProvider {
  
  /// Fetches departures from one or more stops, using the `departures.json` API
  /// - Parameters:
  ///   - stopCodes: Stop codes, which have to be in the same region
  ///   - fromDate: Date of first departure to fetch
  ///   - filters: Optional filters, that are treated as an "OR" condition.
  ///   - limit: Maximum number of departures to fetch; not that API might return more than that if multiple departures are at the same time. Defaults to 10.
  ///   - region: Region that the stops are in
  /// - Returns: API response of departures from those stops
  public static func fetchDepartures(stopCodes: [String], fromDate: Date, filters: [Filter] = [], limit: Int = 10, in region: TKRegion) async throws -> TKAPI.Departures {
    
    guard !stopCodes.isEmpty else {
      throw InputError.missingField("stopCodes")
    }
    
    var paras: [String: Any] = [
      "region": region.code,
      "embarkationStops": stopCodes,
      "timeStamp": Int(fromDate.timeIntervalSince1970),
      "limit": limit,
      "config": TKAPIConfig.userSettings().paras,
    ]
    
    if !filters.isEmpty {
      paras["filters"] = filters.map { filter in
        var inner: [String: String] = [
          "operatorID": filter.operatorID
        ]
        if let routeID = filter.routeID {
          inner["routeID"] = routeID
        }
        if let directionID = filter.directionID {
          inner["directionID"] = directionID
        }
        return inner
      }
    }
    
    let response = await TKServer.shared.hit(
      TKAPI.Departures.self,
      .POST,
      path: "departures.json",
      parameters: paras,
      region: region
    )
    return try response.result.get()
  }
  
  public static func downloadDepartures(for stops: [StopLocation], fromDate: Date, filters: [Filter] = [], limit: Int = 10) async throws -> Bool {
    guard let context = stops.first?.managedObjectContext else {
      throw OutputError.stopSinceDeleted
    }
    
    let (region, stopCodes) = try await context.tk_performThrowing {
      guard let region = stops.first?.region else {
        throw OutputError.couldNotFetchRegions
      }
      return (region, stops.map(\.stopCode))
    }
    
    let departures = try await Self.fetchDepartures(stopCodes: stopCodes, fromDate: fromDate, filters: filters, limit: limit, in: region)
    
    return await context.tk_perform {
      TKDeparturesProvider.addDepartures(departures, to: stops)
    }
  }
  
}

// MARK: - Departures.json for stop-to-stop

extension TKDeparturesProvider {
  
  public static func fetchDepartures(for table: TKDLSTable, fromDate: Date = Date(), limit: Int = 10) async throws -> TKAPI.Departures {
    
    let paras = TKDeparturesProvider.queryParameters(for: table, fromDate: fromDate, limit: limit)
    
    let response = await TKServer.shared.hit(
      TKAPI.Departures.self,
      .POST,
      path: "departures.json",
      parameters: paras,
      region: table.startRegion
    )
    return try response.result.get()
  }
  
  public static func downloadDepartures(for table: TKDLSTable, fromDate: Date, limit: Int = 10) async throws -> Set<String> {
    
    let departures = try await fetchDepartures(for: table, fromDate: fromDate, limit: limit)
    let context = table.tripKitContext
    return await context.tk_perform {
      TKDeparturesProvider.addDepartures(departures, into: context)
    }
  }
  
  public static func queryParameters(for table: TKDLSTable, fromDate: Date, limit: Int) -> [String: Any] {
    return [
      "region": table.startRegion.code,
      "disembarkationRegion": table.endRegion.code,
      "timeStamp": Int(fromDate.timeIntervalSince1970),
      "embarkationStops": [table.startStopCode],
      "disembarkationStops": [table.endStopCode],
      "limit": limit,
      "config": TKAPIConfig.userSettings().paras
    ]
  }
  
}

// MARK: - API to Core Data

extension TKDeparturesProvider {
  
  public static func addDepartures(_ departures: TKAPI.Departures, to stops: [StopLocation]) -> Bool {
    
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
      let hashCodes = $0.alertHashCodes
      guard !hashCodes.isEmpty else { return }
      lookup[$0.code]?.forEach { $0.alertHashCodes = hashCodes.map(NSNumber.init) }
    }
    
    return addedStops
  }
  
  public static func addDepartures(_ departures: TKAPI.Departures, into context: NSManagedObjectContext) -> Set<String> {
    
    // First, we make sure we have all the stops
    let stops = (departures.stops ?? [])
      .map { TKAPIToCoreDataConverter.fetchOrInsertNewStopLocation(from: $0, into: context) }
    
    // Next, we collect the existing stops to add content to
    let flattened = stops.flatMap {
      return [$0] + ($0.children ?? [])
    }
    let candidates = Dictionary(grouping: flattened) { $0.stopCode }
    
    // Now, we can add all the stops
    var pairIdentifieres = Set<String>()
    for embarkation in departures.embarkationStops {
      guard let startStop = candidates[embarkation.stopCode]?.first else {
        TKLog.info("Got an embarkation but no stop to add it to: \(embarkation). Stops: \(candidates)")
        continue
      }
      
      for serviceModel in embarkation.services {
        guard
          let endStopCode = serviceModel.endStopCode,
          let endStop = candidates[endStopCode]?.first else {
            TKLog.info("Got an disembarkation but no stop to add it to: \(embarkation). Stops: \(candidates)")
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
//    assert(!pairIdentifieres.isEmpty, "No embarkations in \(departures)")
    
    TKAPIToCoreDataConverter.updateOrAddAlerts(departures.alerts, in: context)
    
    return pairIdentifieres
  }
  
}

#endif
