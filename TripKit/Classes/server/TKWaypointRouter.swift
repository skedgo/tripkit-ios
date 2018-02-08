//
//  TKWaypointRouter.swift
//  TripKit
//
//  Created by Adrian Schoenig on 31/08/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

extension TKWaypointRouter {
  // MARK: - Trip patterns + next trips
  
  /// Calculates a trip based on the provided trip, with the new trip being a trip
  /// that both departs after the current time and after the provided trip.
  ///
  /// - Parameters:
  ///   - trip: The trip for which to get the next departure
  ///   - vehicles: Optional vehicles that should be for private vehicles segments
  ///   - completion: Handler called on success with a trip or on error (with optional `Error`)
  @objc public func fetchNextTrip(after trip: Trip, using vehicles: [STKVehicular] = [], completion: @escaping (Trip?, Error?) -> Void) {
    
    SVKServer.shared.requireRegions { error in
      guard let region = trip.request.startRegion() else {
        
        completion(nil, error)
        return
      }
      
      let pattern = TKTripPattern.pattern(for: trip)
      let paras = TKWaypointRouter.nextTripParas(pattern: pattern, departure: trip.departureTime, using: vehicles)
      self.fetchTrip(waypointParas: paras, region: region, into: trip.tripGroup, completion: completion)
    }
  }
  
  
  /// Calculates a trip from the provided pattern that's departing both after the
  /// provided time and after now (i.e., whichever is later).
  ///
  /// - Parameters:
  ///   - pattern: The pattern that's used as input to calculate a trip
  ///   - departure: Departure time for new trip (ignored if before current time)
  ///   - vehicles: Optional vehicles that should be for private vehicles segments
  ///   - tripKit: TripKit instance into which the new trip will be inserted
  ///   - region: The region where the trip starts
  ///   - completion: Handler called on success with a trip or on error (with optional `Error`)
  @objc public func fetchTrip(pattern: [TKSegmentPattern], departure: Date, using vehicles: [STKVehicular] = [], into tripKit: TKTripKit, in region: SVKRegion, completion: @escaping (Trip?, Error?) -> Void) {
    
    let paras = TKWaypointRouter.nextTripParas(pattern: pattern, departure: departure, using: vehicles)
    
    self.fetchTrip(waypointParas: paras, region: region, into: tripKit.tripKitContext, completion: completion)
  }
  
  
  private static func nextTripParas(pattern: [TKSegmentPattern], departure: Date, using vehicles: [STKVehicular]) -> [String: Any] {
    
    let now = Date()
    let leaveAt = departure > now ? departure : now
    
    var paras = [String: Any]()
    paras["config"]   = TKSettings.defaultDictionary()
    paras["vehicles"] = TKAPIToCoreDataConverter.vehiclesPayload(for: vehicles)
    paras["segments"] = pattern
    paras["leaveAt"]  = leaveAt.timeIntervalSince1970 + 60
    return paras
  }
  
  
  // MARK: - Tuning public transport trips
  
  @objc public func fetchTrip(moving segment: TKSegment, to visit: StopVisits, atStart: Bool, usingPrivateVehicles vehicles: [STKVehicular], completion: @escaping (Trip?, Error?) -> Void) {
    
    SVKServer.shared.requireRegions { error in
      let request = segment.trip.request
      guard let region = request.startRegion(), error == nil else {
        completion(nil, error)
        return
      }
      
      let builder = WaypointParasBuilder(privateVehicles: vehicles)
      let paras = builder.build(moving: segment, to: visit, atStart: atStart)
      
      // Will have new pattern, so we'll add it to the request rather than
      // to the original trip group.
      self.fetchTrip(waypointParas: paras, region: region, into: segment.trip.request, completion: completion)
    }
    
  }
  
  // MARK: - Helpers
  
  /// For calculating a trip and adding it to an existing trip group.
  ///
  /// - note: Only use this method if the calculated trip will fit that
  ///     trip group as this will not be checked separately. It will fit
  ///     if it's using the same modes and same/similar stops.
  private func fetchTrip(waypointParas: [String: Any], region: SVKRegion, into tripGroup: TripGroup, completion: @escaping (Trip?, Error?) -> Void) {
    guard let context = tripGroup.managedObjectContext else {
      completion(nil, nil)
      return
    }
    
    fetchTrip(
      waypointParas: waypointParas,
      region: region,
      into: context,
      parserHandler: { json, parser in
        parser.parseAndAddResult(json, into: tripGroup, merging: false) { trips in
          completion(trips.first, nil)
        }

      },
      errorHandler: { error in
        completion(nil, error)
      }
    )
  }
  
  /// For calculating a trip and adding it to an existing request
  ///
  /// - note: Only use this method if the calculated trip will have
  ///     the same origin, destination and approximate query time
  ///     as the request as this will not be checked separately.
  private func fetchTrip(waypointParas: [String: Any], region: SVKRegion, into request: TripRequest, completion: @escaping (Trip?, Error?) -> Void) {
    guard let context = request.managedObjectContext else {
      completion(nil, nil)
      return
    }
    
    fetchTrip(
      waypointParas: waypointParas,
      region: region,
      into: context,
      parserHandler: { json, parser in
        parser.parseAndAddResult(json, for: request, merging: false) { trips in
          completion(trips.first, nil)
        }
        
      },
      errorHandler: { error in
        completion(nil, error)
      }
    )
  }
  
  /// For calculating a trip and adding it as a stand-alone trip / request to TripKit
  private func fetchTrip(waypointParas: [String: Any], region: SVKRegion, into context: NSManagedObjectContext, completion: @escaping (Trip?, Error?) -> Void) {
    
    fetchTrip(
      waypointParas: waypointParas,
      region: region,
      into: context,
      parserHandler: { (json, parser) in
        parser.parseAndAddResult(json) { request in
          completion(request?.trips.first, nil)
        }
      },
      errorHandler: { error in
        completion(nil, error)
      }
    )
  }

  private func fetchTrip(waypointParas: [String: Any], region: SVKRegion, into context: NSManagedObjectContext, parserHandler: @escaping ([AnyHashable: Any], TKRoutingParser) -> Void, errorHandler: @escaping (Error?) -> Void) {
    
    let server = SVKServer.shared
    server.hitSkedGo(
      withMethod: "POST",
      path: "waypoint.json",
      parameters: waypointParas,
      region: region,
      callbackOnMain: false,
      success: { status, response, _ in
        guard let json = response as? [AnyHashable: Any] else {
          errorHandler(nil)
          return
        }
        
        context.perform {
          let parser = TKRoutingParser(tripKitContext: context)
          parserHandler(json, parser)
        }
      },
      failure: { (error: Swift.Error?) -> Void in
        context.perform {
          errorHandler(error)
        }
      }
    )
  }
  
}

class WaypointParasBuilder {
  
  private let vehicles: [STKVehicular]
  
  init(privateVehicles vehicles: [STKVehicular] = []) {
    self.vehicles = vehicles
  }
  
  func build(moving segmentToMatch: TKSegment, to visit: StopVisits, atStart: Bool) -> [String: Any] {
    
    assert(!segmentToMatch.isStationary(), "Can't move stationary segments to a visit")
    assert(segmentToMatch.isPublicTransport(), "Can only move public transport segments to a visit")
    
    guard let trip = segmentToMatch.trip else { preconditionFailure() }
    
    var paras: [String: Any]
    paras = [
      "config": TKSettings.defaultDictionary(),
      "vehicles": TKAPIToCoreDataConverter.vehiclesPayload(for: vehicles)
    ]
    
    // First we construct the paras on a segment by segment basis
    var foundMatch = false
    let unglued = trip.segments().flatMap { segment -> (segment: TKSegment, paras: [String: Any])? in
      
      if segmentToMatch == segment {
        foundMatch = true
        let paras = waypointParas(moving: segment, to: visit, atStart: atStart)
        return (segment, paras)
      } else if let paras = waypointParas(for: segment) {
        return (segment, paras)
        
      } else {
        return nil
      }
      
    }
    assert(foundMatch)
    
    // Then we glue them together, making sure that start + end coordinates are matching
    let arrayParas = unglued.enumerated().map { index, current -> [[String: Any]] in
      
      if atStart, index+1 < unglued.count, unglued[index+1].segment == segmentToMatch  {
        var paras = current.paras
        paras["end"] = SVKParserHelper.requestString(for: visit.coordinate)
        return [paras]
      }
      
      if atStart, index == 0, current.segment == segmentToMatch {
        let walk: [String : Any] = [
          "start": SVKParserHelper.requestString(for: trip.request.fromLocation.coordinate),
          "end": SVKParserHelper.requestString(for: visit.coordinate),
          "modes": ["wa_wal"] // Ok, to send this even when on wheelchair. TKSettings take care of that.
        ]
        return [walk, current.paras]
      }
      
      if !atStart, index > 0, unglued[index-1].segment == segmentToMatch {
        var paras = current.paras
        paras["start"] = SVKParserHelper.requestString(for: visit.coordinate)
        return [paras]
      }

      if !atStart, index == unglued.count - 1, current.segment == segmentToMatch {
        let walk: [String : Any] = [
          "start": SVKParserHelper.requestString(for: visit.coordinate),
          "end": SVKParserHelper.requestString(for: trip.request.toLocation.coordinate),
          "modes": ["wa_wal"] // Ok, to send this even when on wheelchair. TKSettings take care of that.
        ]
        return [current.paras, walk]
      }
      
      return [current.paras]
    }
    
    paras["segments"] = Array(arrayParas.joined())
    return paras
  }
  
  private func waypointParas(for segment: TKSegment) -> [String: Any]? {
    if segment.isStationary() {
      return nil
    } else if segment.isPublicTransport() {
      return waypointParas(forPublicTransport: segment)
    } else {
      return waypointParas(forPrivateTransport: segment)
    }
  }
  
  private func waypointParas(forPrivateTransport segment: TKSegment) -> [String: Any] {
    precondition(!segment.isPublicTransport())
    
    guard
      let start = segment.start?.coordinate,
      let end = segment.end?.coordinate,
      let privateMode = segment.modeIdentifier()
      else {
        preconditionFailure()
    }
    
    var paras: [String : Any] = [
      "modes": [privateMode],
      "start": SVKParserHelper.requestString(for: start),
      "end": SVKParserHelper.requestString(for: end)
    ]
    
    if let vehicleUUID = segment.reference?.vehicleUUID {
      paras["vehicleUUID"] = vehicleUUID
    }
    
    return paras
  }
  
  private func waypointParas(forPublicTransport segment: TKSegment) -> [String: Any] {
    precondition(segment.isPublicTransport())
    
    guard
      let startCode = segment.scheduledStartStopCode(),
      let endCode = segment.scheduledEndStopCode(),
      let publicMode = segment.modeIdentifier(),
      let service = segment.service()
      else {
        preconditionFailure()
    }
    
    let startRegion = segment.startRegion() ?? SVKInternationalRegion.shared
    let endRegion   = segment.endRegion()   ?? SVKInternationalRegion.shared
    
    return [
      "modes": [publicMode],
      "serviceTripID": service.code,
      "operator": service.operatorName ?? "",
      "region": startRegion.name,
      "disembarkationRegion": endRegion.name,
      "start": startCode,
      "end": endCode,
      "startTime": segment.departureTime.timeIntervalSince1970,
      "endTime": segment.arrivalTime.timeIntervalSince1970,
    ]
  }
  
  
  private func waypointParas(moving segment: TKSegment, to visit: StopVisits, atStart: Bool) -> [String: Any] {

    var paras = waypointParas(forPublicTransport: segment)
    
    if atStart {
      guard let departure = visit.departure else { preconditionFailure() }
      paras["start"] = visit.stop.stopCode
      paras["startTime"] = departure.timeIntervalSince1970
    
    } else {
      guard let arrival = visit.arrival ?? visit.departure else { preconditionFailure() }
      paras["end"] = visit.stop.stopCode
      paras["endTime"] = arrival.timeIntervalSince1970
    }
    
    return paras
    
  }
  
}

