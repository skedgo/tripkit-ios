//
//  TKDeparturesProvider.swift
//  TripKit
//
//  Created by Adrian Schönig on 01.11.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

@objc
public class TKDeparturesProvider: NSObject {
  private override init() {
    super.init()
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
