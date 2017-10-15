//
//  TKAgendaOutput+Trips.swift
//  TripKit
//
//  Created by Adrian Schoenig on 21/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

import RxSwift

extension TKAgendaOutput {
  
  struct Response: Decodable {
    typealias DictList = [[String: Any]]
    let track: DictList // TODO: This has two things we care about, an "id: String", and a "groups: DictList"
    let segmentTemplates: DictList
    let alerts: DictList
    
    // MARK: Decodable
    private enum CodingKeys: String, CodingKey {
      case track
      case segmentTemplates
      case alerts
    }
    
    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      track = try container.decode(DictList.self, forKey: .track)
      segmentTemplates = try container.decode(DictList.self, forKey: .segmentTemplates)
      alerts = try container.decode(DictList.self, forKey: .alerts)
    }
  }
  
  func addTrips(from response: Response) throws -> Observable<TKAgendaOutput> {
    
    // The parser requires a map of some ID to the raw 'groups' array.
    // We use the ID as defined by `TKAgendaOutput.tripId`.
    let keyToRawGroups: [String: Response.DictList] 
    keyToRawGroups = response.track.reduce(mutating: [:]) { acc, item in
      if let tripId = item["id"] as? String,
         let groups = item["groups"] as? Response.DictList  {
        acc[tripId] = groups
      }
    }
    
    // We can now kick-off the parser, which returns a map of whatever
    // IDs we used above, to a trip list.
    let parser = TKRoutingParser(tripKitContext: TripKit.shared.tripKitContext)
    return parser.rx
      .parseAndAdd(keyToGroups: keyToRawGroups, segmentTemplates: response.segmentTemplates, alerts: response.alerts)
      .map { keyToTrip in
        var withTrips = self
        withTrips.trips = keyToTrip
        withTrips.populateRequests()
        return withTrips
      }
  }
  
}

extension Reactive where Base: TKRoutingParser {
  
  /// Rx-wrapper around the `parseAndAddResult` that's taking `keyToGroups`,
  /// with the special case of returning just a single trip per key.
  fileprivate func parseAndAdd<K>(keyToGroups: [K: [[String: Any]]], segmentTemplates: [[String: Any]], alerts: [[String: Any]]?) -> Observable<[K: Trip]> {
    
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

extension TKAgendaOutput {
  
  fileprivate func populateRequests() {
    typealias FromTo = (fromId: String, toId: String)
    let tripOutputs = track.reduce(mutating: [String: FromTo]()) { acc, item in
      guard case .trip(let from, let id, let to) = item else { return }
      acc[id] = (from, to)
    }
    
    for (key, trip) in trips {
      var from: SGKNamedCoordinate? = nil
      var to: SGKNamedCoordinate? = nil
      var arriveBy: Date? = nil
      var leaveAfter: Date? = nil

      if let fromToIDs = tripOutputs[key] {
        let fromItem = inputs[fromToIDs.fromId] ?? nil
        let toItem = inputs[fromToIDs.toId] ?? nil
        from = SGKNamedCoordinate(for: trip, endpoint: fromItem, order: .start)
        to = SGKNamedCoordinate(for: trip, endpoint: toItem, order: .end)
        leaveAfter = fromItem?.endTime
        arriveBy = toItem?.startTime
        
        if let destination = toItem?.title ?? toItem?.location?.name {
          trip.request.purpose = Loc.To(location: destination)
        }
      }

      TKRoutingParser.populate(trip.request, start: from, end: to, leaveAfter: leaveAfter, arriveBy: arriveBy)
    }
  }
  
}

fileprivate extension SGKNamedCoordinate {
  
  convenience init(for trip: Trip, endpoint item: TKAgendaInput.Item?, order: TKSegmentOrdering) {
    
    let named = SGKNamedCoordinate(item?.location)
    
    let coordinate: CLLocationCoordinate2D
    if let itemCoordinate = named?.coordinate, itemCoordinate.isValid {
      coordinate = itemCoordinate
      
    } else {
      let first = (order == .start)
      let segment = TKRoutingParser.matchingSegment(in: trip, order: .regular, first: first)
      coordinate = first ? segment.start!.coordinate
        : segment.end!.coordinate
    }
    
    self.init(latitude: coordinate.latitude, longitude: coordinate.longitude, name: named?.title, address: named?.address)
  }
  
}

fileprivate extension TKAgendaInput.Item {
  
  var location: TKAgendaInput.Location? {
    switch self {
    case .home(let input):
      return input.location
    case .event(let input):
      return input.location
    case .trip:
      return nil
    }
  }
  
  var startTime: Date? {
    switch self {
    case .event(let input): return input.startTime
    case .home, .trip: return nil
    }
  }
  
  var endTime: Date? {
    switch self {
    case .event(let input): return input.endTime
    case .home, .trip: return nil
    }
  }
  
  var title: String? {
    switch self {
    case .home(let input): return input.title
    case .event(let input): return input.title
    case .trip: return nil
    }
  }

}
