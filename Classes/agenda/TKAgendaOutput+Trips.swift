//
//  TKAgendaOutput+Trips.swift
//  TripKit
//
//  Created by Adrian Schoenig on 21/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

import Marshal
import RxSwift

extension TKAgendaOutput {
  
  func addTrips(fromServerBody marshaled: MarshaledObject) throws -> Observable<TKAgendaOutput> {
    
    typealias DictList = [[String: Any]]
    let track: DictList = try marshaled.value(for: "track")
    let segmentTemplates: DictList = try marshaled.value(for: "segmentTemplates")
    let alerts: DictList? = try? marshaled.value(for: "alerts")
    
    // The parser requires a map of some ID to the raw 'groups' array.
    // We use the ID as defined by `TKAgendaOutput.tripId`.
    let keyToRawGroups: [String: DictList]
    keyToRawGroups = track.reduce(mutating: [:]) { acc, item in
      if let tripId = try? TKAgendaOutput.tripId(forTrackItem: item),
         let groups: DictList = try? item.value(for: "groups")  {
        acc[tripId] = groups
      }
    }
    
    // We can now kick-off the parser, which returns a map of whatever
    // IDs we used above, to a trip list.
    let parser = TKRoutingParser(tripKitContext: TripKit.shared.tripKitContext)
    return parser.rx
      .parseAndAdd(keyToGroups: keyToRawGroups, segmentTemplates: segmentTemplates, alerts: alerts)
      .map { keyToTrip in
        var withTrips = self
        withTrips.trips = keyToTrip
        
        // TODO: The requests of those trips are not populated, we might want to do that
        //       here, using information from the other track items, i.e., calling
        //       `TKRoutingParser.populate`
        
        return withTrips
      }
  }
  
}

extension Reactive where Base: TKRoutingParser {
  
  /// Rx-wrapper around the `parseAndAddResult` that's taking `keyToGroups`,
  /// with the special case of returning just a single trip per key.
  fileprivate func parseAndAdd<K: Equatable>(keyToGroups: [K: [[String: Any]]], segmentTemplates: [[String: Any]], alerts: [[String: Any]]?) -> Observable<[K: Trip]> {
    
    return Observable.create { subscriber in
      
      self.base.parseAndAddResult(keyToGroups, withSegmentTemplates: segmentTemplates, andAlerts: alerts, completion: { keyToTrips in
        
        let keyToTrip: [K: Trip] = keyToTrips.reduce(mutating: [:]) { acc, item in
          guard let key = item.key as? K, let trips = item.value as? [Trip], let trip = trips.first else {
            assertionFailure()
            return
          }
          acc[key] = trip
        }
        
        subscriber.onNext(keyToTrip)
        subscriber.onCompleted()
      })
      
      return Disposables.create()
    }
    
  }
  
}
