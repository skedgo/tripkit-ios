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
public enum TKWaypointRouter {
  
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
  
}

// MARK: - Trip patterns + next trips

extension TKWaypointRouter {

  /// Calculates a trip based on the provided trip. Departure time is the provided
  /// time or now, whichever is later.
  ///
  /// - Parameters:
  ///   - trip: The trip for which to get the next departure
  ///   - vehicles: Optional vehicles that should be for private vehicles segments
  ///   - completion: Handler called on success with a trip or on error (with optional `Error`)
  public static func fetchNextTrip(after trip: Trip, usingPrivateVehicles vehicles: [TKVehicular] = [], completion: @escaping (Result<Trip, Error>) -> Void) {
    
    TKRegionManager.shared.requireRegions { error in
      guard let region = trip.request.startRegion else {
        completion(.failure(TKWaypointRouter.WaypointError.couldNotFindRegionForTrip))
        return
      }
      
      let pattern = TKTripPattern.pattern(for: trip)
      let paras = TKWaypointRouter.nextTripParas(pattern: pattern, departure: trip.departureTime, using: vehicles)
      self.fetchTrip(waypointParas: paras, region: region, into: trip.tripGroup, completion: completion)
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
    
    TKRegionManager.shared.requireRegions { result in
      if case .failure(let error) = result {
        completion(.failure(error))
        return
      }
      guard let region = segment.trip.request.startRegion else {
        completion(.failure(TKWaypointRouter.WaypointError.couldNotFindRegionForTrip))
        return
      }
      
      do {
        let segments = try Self.segments(moving: segment, to: visit, atStart: atStart)
        let paras = try buildParas(segments: segments, vehicles: vehicles)
        
        // Will have new pattern, so we'll add it to the request rather than
        // to the original trip group.
        self.fetchTrip(waypointParas: paras, region: region, into: segment.trip.request, completion: completion)
      
      } catch {
        completion(.failure(error))
      }
    }
  }
  
  public static func fetchTrip(replacing segment: TKSegment, with entry: DLSEntry, usingPrivateVehicles vehicles: [TKVehicular] = [], completion: @escaping (Result<Trip, Error>) -> Void) {
    
    TKRegionManager.shared.requireRegions { result in
      if case .failure(let error) = result {
        completion(.failure(error))
        return
      }
      guard let region = segment.trip.request.startRegion else {
        completion(.failure(TKWaypointRouter.WaypointError.couldNotFindRegionForTrip))
        return
      }
      
      do {
        let segments = try Self.segments(replacing: segment, with: entry, fallbackRegion: region)
        let paras = try buildParas(segments: segments, vehicles: vehicles)
        
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
    TKRegionManager.shared.requireRegions { result in
      if case .failure(let error) = result {
        completion(.failure(error))
        return
      }
      
      guard let region = segment.trip.request.startRegion else {
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
        let segments: [Segment]
        if isMovingStartOfSegment {
          segments = try Self.segments(movingStartOf: movingSegment, to: location)
        } else {
          segments = try Self.segments(movingEndOf: movingSegment, to: location)
        }

        let paras = try buildParas(segments: segments, vehicles: vehicles)
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
    
    fetchAndParse(
      waypointParas: waypointParas,
      region: region,
      into: context
    ) { _, _, result in
      do {
        let response = try result.get()
        TKRoutingParser.add(response, to: tripGroup, merge: false) { parserResult in
          completion(Result {
            try parserResult.get().first.orThrow(WaypointError.fetchedResultsButGotNoTrip)
          })
        }
      } catch {
        completion(.failure(error))
      }
    }
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
    
    fetchAndParse(
      waypointParas: waypointParas,
      region: region,
      into: context
    ) { _, _, result in
      do {
        let response = try result.get()
        TKRoutingParser.add(response, to: request, merge: false) { parserResult in
          completion(Result {
            try parserResult.get().first.orThrow(WaypointError.fetchedResultsButGotNoTrip)
          })
        }
      } catch {
        completion(.failure(error))
      }
    }
  }
  
  /// For calculating a trip and adding it as a stand-alone trip / request to TripKit
  public static func fetchTrip(waypointParas: [String: Any], region: TKRegion? = nil, into context: NSManagedObjectContext, completion: @escaping (Result<Trip, Error>) -> Void) {
    
    fetchAndParse(
      waypointParas: waypointParas,
      region: region,
      into: context
    ) { _, _, result in
      do {
        let response = try result.get()
        TKRoutingParser.add(response, into: context) { parserResult in
          completion(Result {
            try parserResult.get().trips.first.orThrow(WaypointError.fetchedResultsButGotNoTrip)
          })
        }
      } catch {
        completion(.failure(error))
      }
    }
  }

  private static func fetchAndParse(waypointParas: [String: Any], region: TKRegion?, into context: NSManagedObjectContext, handler: @escaping (Int?, [String: Any], Result<TKAPI.RoutingResponse, Error>) -> Void) {
    
    TKServer.shared.hit(
      TKAPI.RoutingResponse.self,
      .POST, path: "waypoint.json",
      parameters: waypointParas,
      region: region,
      callbackOnMain: true, // we parse on main
      completion: handler
    )
  }
  
}

// MARK: - Input

extension TKWaypointRouter {
  
  struct Input: Encodable {
    var segments: [Segment]
    var vehicles: [TKAPI.PrivateVehicle]
    // var config: TKConfig
  }
  
  enum Location {
    case coordinate(CLLocationCoordinate2D)
    case code(String, TKRegion)
  }
  
  struct Segment: Encodable {
    var start: Location
    var end: Location
    let modes: [String]

    var startTime: Date?
    var endTime: Date?

    /// Private vehicles
    var vehicleUUID: String?

    /// Shared vehicles
    var sharedVehicleID: String?
    
    /// Public transport
    var serviceTripID: String?
    var operatorID: String?
    var operatorName: String?
    
    enum CodingKeys: String, CodingKey {
      case start
      case startRegion = "region"
      case startTime
      case end
      case endRegion = "disembarkationRegion"
      case endTime
      case modes
      case vehicleUUID
      case sharedVehicleID
      case serviceTripID
      case operatorName = "operator"
      case operatorID = "operatorID"
    }
    
    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      
      // required
      switch start {
      case .coordinate(let coordinate):
        try container.encode(TKParserHelper.requestString(for: coordinate), forKey: .start)
      case .code(let string, let region):
        try container.encode(string, forKey: .start)
        try container.encode(region.name, forKey: .startRegion)
      }
      switch end {
      case .coordinate(let coordinate):
        try container.encode(TKParserHelper.requestString(for: coordinate), forKey: .end)
      case .code(let string, let region):
        try container.encode(string, forKey: .end)
        try container.encode(region.name, forKey: .endRegion)
      }
      try container.encode(modes, forKey: .modes)

      // optional
      try container.encodeIfPresent(startTime, forKey: .startTime)
      try container.encodeIfPresent(endTime, forKey: .endTime)
      try container.encodeIfPresent(vehicleUUID, forKey: .vehicleUUID)
      try container.encodeIfPresent(sharedVehicleID, forKey: .sharedVehicleID)
      try container.encodeIfPresent(serviceTripID, forKey: .serviceTripID)
      try container.encodeIfPresent(operatorID, forKey: .operatorID)
      try container.encodeIfPresent(operatorName, forKey: .operatorName)
    }
  }
  
}

extension TKWaypointRouter.Segment {
  
  init(service: Service, mode: String, start: TKWaypointRouter.Location, end: TKWaypointRouter.Location, startTime: Date? = nil, endTime: Date? = nil) {
    self.init(
      start: start,
      end: end,
      modes: [mode],
      startTime: startTime,
      endTime: endTime,
      serviceTripID: service.code,
      operatorID: service.operatorID,
      operatorName: service.operatorName
    )
  }
  
}

extension TKWaypointRouter {
  
  static func buildParas(segments: [TKWaypointRouter.Segment], vehicles: [TKVehicular]) throws -> [String: Any] {
    let input = TKWaypointRouter.Input(
      segments: segments,
      vehicles: vehicles.map { $0.toModel() }
    )
    
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .secondsSince1970
#if DEBUG
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
#endif
    let data = try encoder.encode(input)
    var object = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    object["config"] = TKSettings.config
    return object
  }
  
  static func segments(moving segmentToMatch: TKSegment, to visit: StopVisits, atStart: Bool) throws -> [TKWaypointRouter.Segment] {
    
    assert(!segmentToMatch.isStationary, "Can't move stationary segments to a visit")
    assert(segmentToMatch.isPublicTransport, "Can only move public transport segments to a visit")
    
    guard let trip = segmentToMatch.trip else { preconditionFailure() }
    
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
      .map(\.element)
    
    // Construct the paras on a segment-by-segment basis
    var foundMatch = false
    let unglued = try prunedSegments.map { segment -> (segment: TKSegment, input: TKWaypointRouter.Segment) in
      if segmentToMatch == segment {
        foundMatch = true
        let paras = try waypointSegment(moving: segment, to: visit, atStart: atStart)
        return (segment, paras)
      } else {
        let paras = try waypointSegment(forNonStationary: segment)
        return (segment, paras)
      }
    }
    assert(foundMatch)
    
    // Glue them together, making sure that start + end coordinates are matching
    return unglued.enumerated().flatMap { index, current -> [TKWaypointRouter.Segment] in
      
      // If the next segment is the one to change the embarkation, extend the
      // end to that location.
      if atStart, index+1 < unglued.count, unglued[index+1].segment == segmentToMatch  {
        var input = current.input
        input.end = .coordinate(visit.coordinate) // not stop code, as this is a non-PT segment
        return [input]
      }
      
      // If you change the embaraktion at the very start, we need to add an additional
      // walk.
      if atStart, index == 0, current.segment == segmentToMatch {
        let walk = TKWaypointRouter.Segment(
          start: .coordinate(trip.request.fromLocation.coordinate),
          end: .coordinate(visit.coordinate), // not stop code, as this is a walking segment
          modes: ["wa_wal"] // Ok, to send this even when on wheelchair. TKSettings take care of that.
        )
        return [walk, current.input]
      }
      
      if !atStart, index > 0, unglued[index-1].segment == segmentToMatch {
        var input = current.input
        input.start = .coordinate(visit.coordinate) // not stop code, as this is a non-PT segment
        return [input]
      }
      if !atStart, index == unglued.count - 1, current.segment == segmentToMatch {
        let walk = TKWaypointRouter.Segment(
          start: .coordinate(visit.coordinate), // not stop code, as this is a walking segment
          end: .coordinate(trip.request.toLocation.coordinate),
          modes: ["wa_wal"] // Ok, to send this even when on wheelchair. TKSettings take care of that.
        )
        return [current.input, walk]
      }
      
      return [current.input]
    }
  }
  
  // MARK: - Public transport
  
  private static func segments(replacing prototype: TKSegment, with entry: DLSEntry, fallbackRegion: TKRegion) throws -> [TKWaypointRouter.Segment] {
    guard let identifier = prototype.modeIdentifier else {
      throw TKWaypointRouter.WaypointError.builderIsMissingRequiredInput("segment.modeIdentifier")
    }

    // continuations are taken care of by the entry's send stop and segment's `finalSegment`
    let relevantSegments = prototype.trip.segments.filter { !$0.isContinuation && !$0.isStationary }
    return try relevantSegments.map { segment -> TKWaypointRouter.Segment in
      if segment == prototype {
        return try waypointSegment(for: entry, mode: identifier, fallbackRegion: fallbackRegion)
      } else {
        return try waypointSegment(forMoving: segment)
      }
    }
  }
  
  private static func waypointSegment(forNonStationary segment: TKSegment) throws -> TKWaypointRouter.Segment {
    assert(!segment.isStationary)
    if segment.isPublicTransport {
      return try waypointSegment(forPublicTransport: segment)
    } else {
      return try waypointSegment(forMoving: segment)
    }
  }
  
  private static func waypointSegment(forPublicTransport segment: TKSegment) throws -> TKWaypointRouter.Segment {
    precondition(segment.isPublicTransport)
    
    guard
      let startCode = segment.scheduledStartStopCode,
      let endCode = segment.scheduledEndStopCode,
      let publicMode = segment.modeIdentifier,
      let service = segment.service
      else {
        throw TKWaypointRouter.WaypointError.builderIsMissingRequiredInput("Segment is missing required public transport information.")
    }
    
    return .init(
      service: service,
      mode: publicMode,
      start: .code(startCode, segment.startRegion ?? .international),
      end: .code(endCode, segment.endRegion   ?? .international),
      startTime: segment.departureTime,
      endTime: segment.arrivalTime
    )
  }
  
  private static func waypointSegment(forMoving segment: TKSegment) throws -> TKWaypointRouter.Segment {
    guard
      let start = segment.start?.coordinate,
      let end = segment.end?.coordinate,
      let privateMode = segment.modeIdentifier
      else {
        throw TKWaypointRouter.WaypointError.builderIsMissingRequiredInput("Segment is missing start, end, or mode.")
    }
    
    return .init(
      start: .coordinate(start),
      end: .coordinate(end),
      modes: [privateMode],
      vehicleUUID: segment.reference?.vehicleUUID,
      sharedVehicleID: segment.sharedVehicle?.identifier
    )
  }
  
  private static func waypointSegment(for entry: DLSEntry, mode: String, fallbackRegion: TKRegion) throws -> TKWaypointRouter.Segment {
    guard let departure = entry.departure, let arrival = entry.arrival else {
      throw TKWaypointRouter.WaypointError.cannotMoveToFrequencyBasedVisit
    }
    
    return .init(
      service: entry.service,
      mode: mode,
      start: .code(entry.stop.stopCode, entry.stop.region ?? fallbackRegion),
      end: .code(entry.endStop.stopCode, entry.endStop.region ?? fallbackRegion),
      startTime: departure,
      endTime: arrival
    )
  }

  private static func waypointSegment(moving segment: TKSegment, to visit: StopVisits, atStart: Bool) throws -> TKWaypointRouter.Segment {
    guard
      case .timetabled(let arrival, let departure) = visit.timing,
      let service = segment.service,
      let mode = segment.modeIdentifier
    else {
      throw TKWaypointRouter.WaypointError.cannotMoveToFrequencyBasedVisit
    }
    
    if atStart {
      guard let departure = departure, let endCode = segment.scheduledEndStopCode else { throw TKWaypointRouter.WaypointError.timetabledVisitIsMissingTimes }
      return .init(
        service: service,
        mode: mode,
        start: .code(visit.stop.stopCode, visit.stop.region ?? segment.startRegion ?? .international),
        end: .code(endCode, segment.endRegion ?? .international),
        startTime: departure,
        endTime: segment.arrivalTime
      )

    } else {
      guard let arrival = arrival ?? departure, let startCode = segment.scheduledStartStopCode else { throw TKWaypointRouter.WaypointError.timetabledVisitIsMissingTimes }
      return .init(
        service: service,
        mode: mode,
        start: .code(startCode, segment.startRegion ?? .international),
        end: .code(visit.stop.stopCode, visit.stop.region ?? segment.endRegion ?? .international),
        startTime: segment.departureTime,
        endTime: arrival
      )
    }
  }
  
  static func segments(movingStartOf prototype: TKSegment, to location: TKModeCoordinate) throws -> [TKWaypointRouter.Segment] {
    guard
      let trip = prototype.trip,
      let oldSharingMode = prototype.modeIdentifier,
      let newSharingMode = location.stopModeInfo.identifier, // Might be different, when picking different provider
      let segmentEnd = prototype.end?.coordinate
      else { throw TKWaypointRouter.WaypointError.segmentNotEligible }
    
    var nonSharingModes = trip.usedModeIdentifiers
    nonSharingModes.remove(oldSharingMode)
    if nonSharingModes.isEmpty {
      nonSharingModes.insert("wa_wal")
    }
    
    let a: TKWaypointRouter.Location = .coordinate(trip.request.fromLocation.coordinate)
    let b: TKWaypointRouter.Location = .coordinate(location.coordinate)
    let c: TKWaypointRouter.Location = .coordinate(segmentEnd)
    let d: TKWaypointRouter.Location = .coordinate(trip.request.toLocation.coordinate)
    
    return [
      // 1. Get to the vehicle using non-sharing modes
      .init(
        start: a,
        end: b,
        modes: Array(nonSharingModes),
        startTime: trip.departureTime
      ),
      
      // 2. Use the vehicle to its destination
      .init(
        start: b,
        end: c,
        modes: [newSharingMode],
        sharedVehicleID: (location as? TKFreeFloatingVehicleLocation)?.vehicle.identifier
      ),
      
      // 3. From there, use the other non-sharing modes
      .init(
        start: c,
        end: d,
        modes: Array(nonSharingModes)
      ),
    ]
  }
  
  static func segments(movingEndOf prototype: TKSegment, to location: TKModeCoordinate) throws -> [TKWaypointRouter.Segment] {
    guard
      let trip = prototype.trip,
      let sharingMode = prototype.modeIdentifier,
      let segmentStart = prototype.start?.coordinate
      else { throw TKWaypointRouter.WaypointError.segmentNotEligible }
    
    var nonSharingModes = trip.usedModeIdentifiers
    nonSharingModes.remove(sharingMode)
    if nonSharingModes.isEmpty {
      nonSharingModes.insert("wa_wal")
    }
    
    let a: TKWaypointRouter.Location = .coordinate(trip.request.fromLocation.coordinate)
    let b: TKWaypointRouter.Location = .coordinate(segmentStart)
    let c: TKWaypointRouter.Location = .coordinate(location.coordinate)
    let d: TKWaypointRouter.Location = .coordinate(trip.request.toLocation.coordinate)
    
    return [
      // 1. Get to the vehicle using non-sharing modes
      .init(
        start: a,
        end: b,
        modes: Array(nonSharingModes),
        startTime: trip.departureTime
      ),
      
      // 2. Take the vehicle to the new destination destination
      .init(
        start: b,
        end: c,
        modes: [sharingMode],
        sharedVehicleID: prototype.sharedVehicle?.identifier
      ),
      
      // 3. From there, use the other non-sharing modes
      .init(
        start: c,
        end: d,
        modes: Array(nonSharingModes)
      ),
    ]
  }
  

    
}
