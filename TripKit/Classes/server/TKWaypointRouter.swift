//
//  TKWaypointRouter.swift
//  TripKit
//
//  Created by Adrian Schoenig on 31/08/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

fileprivate extension Result {
  func callHandler(_ handler: (Success?, Failure?) -> Void) {
    switch self {
    case .success(let success): handler(success, nil)
    case .failure(let error): handler(nil, error)
    }
  }
}

/// Provides helper methods around TripGo API's `waypoint.json` endpoint
///
/// For planning A-to-B-via-C trips, including building trip that follow a specific segment pattern.
public class TKWaypointRouter: NSObject {
  
  public enum WaypointError: Error {
    case cannotMoveToFrequencyBasedVisit
    case timetabledVisitIsMissingTimes

    case couldNotFindRegionForTrip
    case builderIsMissingRequiredInput(String)
    case segmentNotEligible

    case tripGotDisassociatedFromCoreData
    case fetchedResultsButGotNoTrip
    case serverFailedWithUnknownError
  }
  
  private override init() {
    super.init()
  }
  
}

// MARK: - Trip patterns + next trips

extension TKWaypointRouter {
  
  /// :nodoc:
  @objc(fetchNextTripAfter:usingPrivateVehicles:completion:)
  public static func _fetchNextTrip(after trip: Trip, usingPrivateVehicles vehicles: [TKVehicular] = [], completion: @escaping (Trip?, Error?) -> Void) {
    fetchNextTrip(after: trip, usingPrivateVehicles: vehicles) { (result: Result<Trip, Error>) in
      result.callHandler(completion)
    }
  }

  /// Calculates a trip based on the provided trip. Departure time is the provided
  /// time or now, whichever is later.
  ///
  /// - Parameters:
  ///   - trip: The trip for which to get the next departure
  ///   - vehicles: Optional vehicles that should be for private vehicles segments
  ///   - completion: Handler called on success with a trip or on error (with optional `Error`)
  public static func fetchNextTrip(after trip: Trip, usingPrivateVehicles vehicles: [TKVehicular] = [], completion: @escaping (Result<Trip, Error>) -> Void) {
    
    TKServer.shared.requireRegions { error in
      guard let region = trip.request.startRegion() else {
        completion(.failure(TKWaypointRouter.WaypointError.couldNotFindRegionForTrip))
        return
      }
      
      let pattern = TKTripPattern.pattern(for: trip)
      let paras = TKWaypointRouter.nextTripParas(pattern: pattern, departure: trip.departureTime, using: vehicles)
      self.fetchTrip(waypointParas: paras, region: region, into: trip.tripGroup, completion: completion)
    }
  }
  
  
  /// :nodoc:
  @objc(fetchTripWithPattern:departure:usingPrivateVehicles:intoTripKit:inRegion:completion:)
  public static func _fetchTrip(pattern: [TKSegmentPattern], departure: Date, usingPrivateVehicles vehicles: [TKVehicular] = [], into tripKit: TKTripKit, in region: TKRegion, completion: @escaping (Trip?, Error?) -> Void) {
    fetchTrip(pattern: pattern, departure: departure, usingPrivateVehicles: vehicles, into: tripKit, in: region) { (result: Result<Trip, Error>) in
      result.callHandler(completion)
    }
  }
  
  /// Calculates a trip from the provided pattern. Departure time is the provided
  /// time or now, whichever is later.
  ///
  /// - Parameters:
  ///   - pattern: The pattern that's used as input to calculate a trip
  ///   - departure: Departure time for new trip (ignored if before current time)
  ///   - vehicles: Optional vehicles that should be for private vehicles segments
  ///   - tripKit: TripKit instance into which the new trip will be inserted
  ///   - region: The region where the trip starts
  ///   - completion: Handler called on success with a trip or on error (with optional `Error`)
  public static func fetchTrip(pattern: [TKSegmentPattern], departure: Date, usingPrivateVehicles vehicles: [TKVehicular] = [], into tripKit: TKTripKit = TripKit.shared, in region: TKRegion, completion: @escaping (Result<Trip, Error>) -> Void) {
    
    let paras = TKWaypointRouter.nextTripParas(pattern: pattern, departure: departure, using: vehicles)
    fetchTrip(waypointParas: paras, region: region, into: tripKit.tripKitContext, completion: completion)
  }
  
  
  private static func nextTripParas(pattern: [TKSegmentPattern], departure: Date, using vehicles: [TKVehicular]) -> [String: Any] {
    
    let now = Date()
    let leaveAt = departure > now ? departure : now
    
    var paras = [String: Any]()
    paras["config"]   = TKSettings.config
    paras["vehicles"] = TKAPIToCoreDataConverter.vehiclesPayload(for: vehicles)
    paras["segments"] = pattern
    paras["leaveAt"]  = leaveAt.timeIntervalSince1970 + 60
    return paras
  }
  
}

// MARK: - Tuning public transport trips

extension TKWaypointRouter {
  /// :nodoc:
  @objc(fetchTripMovingSegment:toVisit:atStart:usingPrivateVehicles:completion:)
  public static func _fetchTrip(moving segment: TKSegment, to visit: StopVisits, atStart: Bool, usingPrivateVehicles vehicles: [TKVehicular] = [], completion: @escaping (Trip?, Error?) -> Void) {
    fetchTrip(moving: segment, to: visit, atStart: atStart, usingPrivateVehicles: vehicles) { (result: Result<Trip, Error>) in
      result.callHandler(completion)
    }
  }

  
  /// Calculates a trip from the provided trip (implied by the segment), which moves
  /// where to get on or off the provided `segment` to the provided `visit`.
  ///
  /// - Parameters:
  ///   - segment: The segment for which to change getting on/off
  ///   - visit: The visit along this segment to get on/off
  ///   - atStart: `true` if getting on should change, `false` if getting off should change
  ///   - vehicles: The private vehicles to use for private vehicle segments
  ///   - completion: Handler called on success with a trip or on error (with optional `Error`)
  public static func fetchTrip(moving segment: TKSegment, to visit: StopVisits, atStart: Bool, usingPrivateVehicles vehicles: [TKVehicular] = [], completion: @escaping (Result<Trip, Error>) -> Void) {
    
    TKServer.shared.requireRegions { error in
      if let error = error {
        completion(.failure(error))
        return
      }
      guard let region = segment.trip.request.startRegion() else {
        completion(.failure(TKWaypointRouter.WaypointError.couldNotFindRegionForTrip))
        return
      }
      
      do {
        let builder = WaypointParasBuilder(privateVehicles: vehicles)
        let paras = try builder.build(moving: segment, to: visit, atStart: atStart)
        
        // Will have new pattern, so we'll add it to the request rather than
        // to the original trip group.
        self.fetchTrip(waypointParas: paras, region: region, into: segment.trip.request, completion: completion)
      
      } catch {
        completion(.failure(error))
      }
    }
  }
  
  /// :nodoc:
  @objc(fetchTripReplacingSegment:withDLSEntry:usingPrivateVehicles:completion:)
  public static func _fetchTrip(replacing segment: TKSegment, with entry: DLSEntry, usingPrivateVehicles vehicles: [TKVehicular] = [], completion: @escaping (Trip?, Error?) -> Void) {
    self.fetchTrip(replacing: segment, with: entry, usingPrivateVehicles: vehicles) { (result: Result<Trip, Error>) in
      result.callHandler(completion)
    }
  }
  
  public static func fetchTrip(replacing segment: TKSegment, with entry: DLSEntry, usingPrivateVehicles vehicles: [TKVehicular] = [], completion: @escaping (Result<Trip, Error>) -> Void) {
    
    TKServer.shared.requireRegions { error in
      if let error = error {
        completion(.failure(error))
        return
      }
      guard let region = segment.trip.request.startRegion() else {
        completion(.failure(TKWaypointRouter.WaypointError.couldNotFindRegionForTrip))
        return
      }
      
      do {
        let builder = WaypointParasBuilder(privateVehicles: vehicles)
        let paras = try builder.build(replacing: segment, with: entry, fallbackRegion: region)
        
        // Will have the same pattern, so we'll add it to original trip group
        self.fetchTrip(waypointParas: paras, region: region, into: segment.trip.tripGroup, completion: completion)
        
      } catch {
        completion(.failure(error))
      }
    }
    
  }
  
}

// MARK: - Picking different shared vehicles

extension TKWaypointRouter {
  
  public static func fetchTrip(byMoving segment: TKSegment, to location: TKModeCoordinate, usingPrivateVehicles vehicles: [TKVehicular] = [], completion: @escaping (Result<Trip, Error>) -> Void) {
    TKServer.shared.requireRegions { error in
      if let error = error {
        completion(.failure(error))
        return
      }
      
      guard let region = segment.trip.request.startRegion() else {
        completion(.failure(TKWaypointRouter.WaypointError.couldNotFindRegionForTrip))
        return
      }
      
      let movingSegment: TKSegment
      let isMovingStartOfSegment: Bool
      
      if segment.hasCarParks, let mover = segment.previous {
        movingSegment = mover
        isMovingStartOfSegment = false
      } else if segment.stationaryType == .vehicleCollect, let mover = segment.next {
        movingSegment = mover
        isMovingStartOfSegment = true
      } else {
        movingSegment = segment
        isMovingStartOfSegment = true
      }
      
      do {
        let builder = WaypointParasBuilder(privateVehicles: vehicles)
        
        let paras: [String: Any]
        if isMovingStartOfSegment {
          paras = try builder.build(movingStartOf: movingSegment, to: location)
        } else {
          paras = try builder.build(movingEndOf: movingSegment, to: location)
        }
        
        self.fetchTrip(waypointParas: paras, region: region, into: segment.trip.tripGroup, completion: completion)
      } catch {
        completion(.failure(error))
      }
    }
  }
  
}

// MARK: - Helpers

extension TKWaypointRouter {
  
  /// For calculating a trip and adding it to an existing trip group.
  ///
  /// - note: Only use this method if the calculated trip will fit that
  ///     trip group as this will not be checked separately. It will fit
  ///     if it's using the same modes and same/similar stops.
  private static func fetchTrip(waypointParas: [String: Any], region: TKRegion, into tripGroup: TripGroup, completion: @escaping (Result<Trip, Error>) -> Void) {
    guard let context = tripGroup.managedObjectContext else {
      completion(.failure(TKWaypointRouter.WaypointError.tripGotDisassociatedFromCoreData))
      return
    }
    
    fetchTrip(
      waypointParas: waypointParas,
      region: region,
      into: context,
      parserHandler: { json, parser in
        parser.parseAndAddResult(json, into: tripGroup, merging: false) { trips in
          if let trip = trips.first {
            completion(.success(trip))
          } else {
            completion(.failure(TKWaypointRouter.WaypointError.fetchedResultsButGotNoTrip))
          }
        }

      },
      errorHandler: { error in
        completion(.failure(error))
      }
    )
  }
  
  /// For calculating a trip and adding it to an existing request
  ///
  /// - note: Only use this method if the calculated trip will have
  ///     the same origin, destination and approximate query time
  ///     as the request as this will not be checked separately.
  private static func fetchTrip(waypointParas: [String: Any], region: TKRegion, into request: TripRequest, completion: @escaping (Result<Trip, Error>) -> Void) {
    guard let context = request.managedObjectContext else {
      completion(.failure(TKWaypointRouter.WaypointError.tripGotDisassociatedFromCoreData))
      return
    }
    
    fetchTrip(
      waypointParas: waypointParas,
      region: region,
      into: context,
      parserHandler: { json, parser in
        let trips = parser.parseAndAddResult(json, for: request, merging: false, visibility: .full)
        if let trip = trips.first {
          completion(.success(trip))
        } else {
          completion(.failure(TKWaypointRouter.WaypointError.fetchedResultsButGotNoTrip))
        }
      },
      errorHandler: { error in
        completion(.failure(error))
      }
    )
  }
  
  /// For calculating a trip and adding it as a stand-alone trip / request to TripKit
  private static func fetchTrip(waypointParas: [String: Any], region: TKRegion, into context: NSManagedObjectContext, completion: @escaping (Result<Trip, Error>) -> Void) {
    
    fetchTrip(
      waypointParas: waypointParas,
      region: region,
      into: context,
      parserHandler: { (json, parser) in
        parser.parseAndAddResult(json) { request in
          if let trip = request?.trips.first {
            completion(.success(trip))
          } else {
            completion(.failure(TKWaypointRouter.WaypointError.fetchedResultsButGotNoTrip))
          }
        }
      },
      errorHandler: { error in
        completion(.failure(error))
      }
    )
  }

  private static func fetchTrip(waypointParas: [String: Any], region: TKRegion, into context: NSManagedObjectContext, parserHandler: @escaping ([AnyHashable: Any], TKRoutingParser) -> Void, errorHandler: @escaping (Error) -> Void) {
    
    let server = TKServer.shared
    server.hitSkedGo(
      withMethod: "POST",
      path: "waypoint.json",
      parameters: waypointParas,
      region: region,
      callbackOnMain: true, // we parse on main
      success: { status, response, _ in
        guard let json = response as? [AnyHashable: Any] else {
          errorHandler(nil ?? TKWaypointRouter.WaypointError.serverFailedWithUnknownError)
          return
        }
        
        let parser = TKRoutingParser(tripKitContext: context)
        parserHandler(json, parser)
      },
      failure: { error in
        errorHandler(error ?? TKWaypointRouter.WaypointError.serverFailedWithUnknownError)
      }
    )
  }
  
}

class WaypointParasBuilder {
  
  private let vehicles: [TKVehicular]
  
  init(privateVehicles vehicles: [TKVehicular] = []) {
    self.vehicles = vehicles
  }
  
  func build(moving segmentToMatch: TKSegment, to visit: StopVisits, atStart: Bool) throws -> [String: Any] {
    
    assert(!segmentToMatch.isStationary, "Can't move stationary segments to a visit")
    assert(segmentToMatch.isPublicTransport, "Can only move public transport segments to a visit")
    
    guard let trip = segmentToMatch.trip else { preconditionFailure() }
    
    var paras: [String: Any] = [
      "config": TKSettings.config,
      "vehicles": TKAPIToCoreDataConverter.vehiclesPayload(for: vehicles)
    ]
    
    // Prune the segments, removing stationary segments...
    let nonStationary = trip.segments.filter { !$0.isStationary }
    
    // ... and walks after driving/cycling
    let prunedSegments = nonStationary
      .enumerated()
      .filter { index, segment in
        if index > 0, segment.isWalking {
          let previous = nonStationary[index - 1]
          return !previous.isDriving && !previous.isCycling && !previous.isSharedVehicle
        } else {
          return true
        }
      }
      .map { $0.element }
    
    // Construct the paras on a segment by segment basis
    var foundMatch = false
    let unglued = try prunedSegments.map { segment -> (segment: TKSegment, paras: [String: Any]) in
      if segmentToMatch == segment {
        foundMatch = true
        let paras = try waypointParas(moving: segment, to: visit, atStart: atStart)
        return (segment, paras)
      } else {
        let paras = try waypointParas(forNonStationary: segment)
        return (segment, paras)
      }
    }
    assert(foundMatch)
    
    // Glue them together, making sure that start + end coordinates are matching
    let arrayParas = unglued.enumerated().map { index, current -> [[String: Any]] in
      
      // If the next segment is the one to change the embarkation, extend the
      // end to that location.
      if atStart, index+1 < unglued.count, unglued[index+1].segment == segmentToMatch  {
        var paras = current.paras
        paras["end"] = TKParserHelper.requestString(for: visit.coordinate)
        return [paras]
      }
      
      // If you change the embaraktion at the very start, we need to add an additional
      // walk.
      if atStart, index == 0, current.segment == segmentToMatch {
        let walk: [String : Any] = [
          "start": TKParserHelper.requestString(for: trip.request.fromLocation.coordinate),
          "end": TKParserHelper.requestString(for: visit.coordinate),
          "modes": ["wa_wal"] // Ok, to send this even when on wheelchair. TKSettings take care of that.
        ]
        return [walk, current.paras]
      }
      
      
      if !atStart, index > 0, unglued[index-1].segment == segmentToMatch {
        var paras = current.paras
        paras["start"] = TKParserHelper.requestString(for: visit.coordinate)
        return [paras]
      }
      if !atStart, index == unglued.count - 1, current.segment == segmentToMatch {
        let walk: [String : Any] = [
          "start": TKParserHelper.requestString(for: visit.coordinate),
          "end": TKParserHelper.requestString(for: trip.request.toLocation.coordinate),
          "modes": ["wa_wal"] // Ok, to send this even when on wheelchair. TKSettings take care of that.
        ]
        return [current.paras, walk]
      }
      
      return [current.paras]
    }
    
    paras["segments"] = Array(arrayParas.joined())
    return paras
  }
  
  private func waypointParas(forNonStationary segment: TKSegment) throws -> [String: Any] {
    assert(!segment.isStationary)
    if segment.isPublicTransport {
      return try waypointParas(forPublicTransport: segment)
    } else {
      return try waypointParas(forMoving: segment)
    }
  }
  
  private func waypointParas(forMoving segment: TKSegment) throws -> [String: Any] {
    guard
      let start = segment.start?.coordinate,
      let end = segment.end?.coordinate,
      let privateMode = segment.modeIdentifier
      else {
        throw TKWaypointRouter.WaypointError.builderIsMissingRequiredInput("Segment is missing start, end, or mode.")
    }
    
    var paras: [String : Any] = [
      "modes": [privateMode],
      "start": TKParserHelper.requestString(for: start),
      "end": TKParserHelper.requestString(for: end)
    ]
    
    if let vehicleUUID = segment.reference?.vehicleUUID {
      paras["vehicleUUID"] = vehicleUUID
    }
    
    return paras
  }
  
  private func waypointParas(forPublicTransport segment: TKSegment) throws -> [String: Any] {
    precondition(segment.isPublicTransport)
    
    guard
      let startCode = segment.scheduledStartStopCode,
      let endCode = segment.scheduledEndStopCode,
      let publicMode = segment.modeIdentifier,
      let service = segment.service
      else {
        throw TKWaypointRouter.WaypointError.builderIsMissingRequiredInput("Segment is missing required public transport information.")
    }
    
    let startRegion = segment.startRegion ?? .international
    let endRegion   = segment.endRegion   ?? .international
    
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
  
  private func waypointParas(moving segment: TKSegment, to visit: StopVisits, atStart: Bool) throws -> [String: Any] {
    guard case .timetabled(let arrival, let departure) = visit.timing else {
      throw TKWaypointRouter.WaypointError.cannotMoveToFrequencyBasedVisit
    }
    
    var paras = try waypointParas(forPublicTransport: segment)
    
    if atStart {
      guard let departure = departure else { throw TKWaypointRouter.WaypointError.timetabledVisitIsMissingTimes }
      paras["start"] = visit.stop.stopCode
      paras["startTime"] = departure.timeIntervalSince1970
    
    } else {
      guard let arrival = arrival ?? departure else { throw TKWaypointRouter.WaypointError.timetabledVisitIsMissingTimes }
      paras["end"] = visit.stop.stopCode
      paras["endTime"] = arrival.timeIntervalSince1970
    }
    
    return paras
  }
  
  func build(replacing prototype: TKSegment, with entry: DLSEntry, fallbackRegion: TKRegion) throws -> [String: Any] {
    guard let identifier = prototype.modeIdentifier else {
      throw TKWaypointRouter.WaypointError.builderIsMissingRequiredInput("segment.modeIdentifier")
    }
    
    var paras: [String: Any] = [
      "config": TKSettings.config,
      "vehicles": TKAPIToCoreDataConverter.vehiclesPayload(for: vehicles)
    ]

    // continuations are taken care of by the entry's send stop and segment's `finalSegment`
    let relevantSegments = prototype.trip.segments.filter { !$0.isContinuation && !$0.isStationary }
    
    let segmentParas = try relevantSegments.map { segment -> [String: Any] in
      if segment == prototype {
        return try waypointParas(for: entry, mode: identifier, fallbackRegion: fallbackRegion)
      } else {
        return try waypointParas(forMoving: segment)
      }
    }

    paras["segments"] = segmentParas
    return paras
  }
  
  private func waypointParas(for entry: DLSEntry, mode: String, fallbackRegion: TKRegion) throws -> [String: Any] {
    guard let departure = entry.departure, let arrival = entry.arrival else {
      throw TKWaypointRouter.WaypointError.cannotMoveToFrequencyBasedVisit
    }

    return [
      "modes": [mode],
      "start": entry.stop.stopCode,
      "end": entry.endStop.stopCode,
      "startTime": departure.timeIntervalSince1970,
      "endTime": arrival.timeIntervalSince1970,
      "serviceTripID": entry.service.code,
      "operator": entry.service.operatorName ?? "",
      "region": entry.stop.region?.name ?? fallbackRegion.name,
      "disembarkationRegion": entry.endStop.region?.name ?? fallbackRegion.name
    ]
  }
  
  func build(movingEndOf prototype: TKSegment, to location: TKModeCoordinate) throws -> [String: Any] {
    guard
      let trip = prototype.trip,
      let sharingMode = prototype.modeIdentifier,
      let segmentStart = prototype.start?.coordinate
      else { throw TKWaypointRouter.WaypointError.segmentNotEligible }
    
    var paras: [String: Any] = [
      "config": TKSettings.config,
      "vehicles": TKAPIToCoreDataConverter.vehiclesPayload(for: vehicles)
    ]
    
    var nonSharingModes = trip.usedModeIdentifiers()
    nonSharingModes.remove(sharingMode)
    if nonSharingModes.isEmpty {
      nonSharingModes.insert("wa_wal")
    }
    
    var waypoints: [[String: Any]] = []
    let a = TKParserHelper.requestString(for: trip.request.fromLocation.coordinate)
    let b = TKParserHelper.requestString(for: segmentStart)
    let c = TKParserHelper.requestString(for: location.coordinate)
    let d = TKParserHelper.requestString(for: trip.request.toLocation.coordinate)
    
    waypoints.append([
      "modes": Array(nonSharingModes),
      "start": a,
      "end": b,
      "startTime": trip.departureTime.timeIntervalSince1970
    ])
    
    waypoints.append([
      "modes": [sharingMode],
      "start": b,
      "end": c
    ])
    
    waypoints.append([
      "modes": Array(nonSharingModes),
      "start": c,
      "end": d
    ])
    
    paras["segments"] = waypoints
    
    return paras
  }
  
  func build(movingStartOf prototype: TKSegment, to location: TKModeCoordinate) throws -> [String: Any] {
    guard
      let trip = prototype.trip,
      let sharingMode = prototype.modeIdentifier,
      let segmentEnd = prototype.end?.coordinate
      else { throw TKWaypointRouter.WaypointError.segmentNotEligible }
    
    var paras: [String: Any] = [
      "config": TKSettings.config,
      "vehicles": TKAPIToCoreDataConverter.vehiclesPayload(for: vehicles)
    ]
    
    var nonSharingModes = trip.usedModeIdentifiers()
    nonSharingModes.remove(sharingMode)
    if nonSharingModes.isEmpty {
      nonSharingModes.insert("wa_wal")
    }

    var waypoints: [[String: Any]] = []
    let a = TKParserHelper.requestString(for: trip.request.fromLocation.coordinate)
    let b = TKParserHelper.requestString(for: location.coordinate)
    let c = TKParserHelper.requestString(for: segmentEnd)
    let d = TKParserHelper.requestString(for: trip.request.toLocation.coordinate)
    
    // 1. Get to the vehicle using non-sharing modes
    waypoints.append([
      "modes": Array(nonSharingModes),
      "start": a,
      "end": b,
      "startTime": trip.departureTime.timeIntervalSince1970
    ])
    
    // 2. Use the vehicle to its destination
    waypoints.append([
      "modes": [location.stopModeInfo.identifier!],
      "start": b,
      "end": c
    ])
    
    // 3. From there, use the other non-sharing modes
    waypoints.append([
      "modes": Array(nonSharingModes),
      "start": c,
      "end": d
    ])

    paras["segments"] = waypoints

    return paras
  }
    
}
