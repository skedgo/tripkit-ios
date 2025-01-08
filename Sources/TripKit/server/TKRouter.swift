//
//  TKRouter.swift
//  TripKit-iOS
//
//  Created by Adrian Schönig on 01.11.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

#if canImport(MapKit)
import MapKit
#endif

extension TKRouter.RoutingError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .invalidRequest(let text): return text
    case .noTripFound: return Loc.NoRoutesFound
    case .startLocationNotDetermined: return "Start location could not be determined. Please try again or select manually" // code: TKErrorCode.userError.rawValue
    case .endLocationNotDetermined: return "End location could not be determined. Please try again or select manually." // code: TKErrorCode.userError.rawValue
    case .routingNotSupported: return Loc.RoutingBetweenTheseLocationsIsNotYetSupported // code: 1001 -- matches server
    }
  }
}

extension TKRouter {
  
#if canImport(CoreData)

  /// The main method to call to have the router calculate trips.
  /// - Parameters:
  ///   - request: An instance of a `TripRequest` which specifies what kind of trips should get calculated.
  ///   - completion: Block called when done, on success or failure
  public func fetchTrips(for request: TripRequest, additional: Set<URLQueryItem>? = nil, visibility: TripGroup.Visibility = .full, callbackQueue: DispatchQueue = .main, completion: @escaping (Result<Void, Error>) -> Void) {
    
    func abort() {
      let error = NSError(code: Int(TKErrorCode.internalError.rawValue), message: "Trip request deleted.")
      callbackQueue.async { completion(.failure(error)) }
    }
    
    guard let context = request.managedObjectContext else {
      return abort()
    }
    
    context.perform {
      guard !request.isDeleted else {
        return abort()
      }
      
      self.fetchTrips(for: request, bestOnly: false, additional: additional, visibility: visibility, callbackQueue: callbackQueue) {
        let result = $0.map { _ in }
        completion(result)
      }
    }
  }
  
  /// The main method to call to have the router calculate trips.
  /// - Parameters:
  ///   - query: An instance of a `TripRequest` which specifies what kind of trips should get calculated.
  ///   - completion: Block called when done, on success or failure
  public func fetchTrips(for query: TKRoutingQuery<NSManagedObjectContext>, completion: @escaping (Result<TripRequest, Error>) -> Void) {
    return fetchTrips(for: query, bestOnly: false, additional: nil, completion: completion)
  }

  /// Kicks off the server request to fetch the best trip matching the request and the enabled
  /// modes according to `TKSettings`.
  ///
  /// On success, the request's `.trips` and `.tripGroup` properties will be set. Note, that these
  /// might include multiple trips (despite the naming of this method), which are variants of the
  /// same trip leaving earlier or later.
  ///
  /// - Parameters:
  ///   - request: The request specifying the query
  ///   - completion: Callback executed when all requests have finished with the original request and, optionally, an error if all failed.
  public func fetchBestTrip(for request: TKRouterRequestable, completion: @escaping (Result<Trip, Error>) -> Void) {

    if let tripRequest = request as? TripRequest {
      tripRequest.expandForFavorite = true
    }

    return fetchTrips(for: request, bestOnly: true, additional: nil) { result in
      completion(result.flatMap { request in
        if let trip = request.trips.first {
          return .success(trip)
        } else {
          return .failure(RoutingError.noTripFound)
        }
      })
    }
  }
  
#endif
  

}

#if canImport(MapKit)
extension TKRoutingQuery {
  public init(from: MKAnnotation, to: MKAnnotation, at time: TKRoutingQueryTime = .leaveASAP, modes: Set<String>, additional: Set<URLQueryItem> = [], context: Context? = nil) {
    self.init(
      from: .init(annotation: from),
      to: .init(annotation: to),
      at: time,
      modes: modes,
      additional: additional,
      context: context
    )
  }
}
#endif

// MARK: - Multi-fetch

#if canImport(CoreData)

extension TKRouter {
  
  /// Kicks off the required server requests asynchronously to the servers, and returns the final result.
  ///
  /// - note: Calling this method will lock-in the departure time for "Leave now" queries.
  ///
  /// As trips get added, they get flagged with full, minimised or hidden visibility.
  /// Which depends on the standard defaults. Check `TKSettings` for setting
  /// those.
  ///
  /// - Parameters:
  ///   - request: The request specifying the query
  ///   - classifier: Optional classifier to assign `TripGroup`'s `classification`
  /// - returns: `TripRequest` with the resulting trip groups associated
  public func multiFetchTrips(for query: TKRoutingQuery<NSManagedObjectContext>, classifier: TKTripClassifier? = nil) async throws -> TripRequest {
    try await withCheckedThrowingContinuation { continuation in
      _ = multiFetchTrips(request: query, modes: query.modes, classifier: classifier) { result in
        continuation.resume(with: result)
      }
    }
  }
  
  /// Kicks off the required server requests asynchronously to the servers. As they
  /// return `progress` is called and the trips get added to TripKit's database. Also
  /// calls `completion` when all are done.
  ///
  /// - note: Calling this method will lock-in the departure time for "Leave now" queries.
  ///
  /// As trips get added, they get flagged with full, minimised or hidden visibility.
  /// Which depends on the standard defaults. Check `TKSettings` for setting
  /// those.
  ///
  /// - Parameters:
  ///   - request: The request specifying the query
  ///   - classifier: Optional classifier to assign `TripGroup`'s `classification`
  ///   - progress: Optional progress callback executed when each request finished, with the number of completed requests passed to the block.
  ///   - completion: Callback executed when all requests have finished with the original request and, optionally, an error if all failed.
  /// - returns: The number of requests sent. This will match the number of times `progress` is called.
  @discardableResult
  public func multiFetchTrips(for query: TKRoutingQuery<NSManagedObjectContext>, classifier: TKTripClassifier? = nil, progress: ((UInt) -> Void)? = nil, completion: @escaping (Result<TripRequest, Error>) -> Void) -> UInt {
    return multiFetchTrips(request: query, modes: query.modes, classifier: classifier, progress: progress, completion: completion)
  }
  
  /// Kicks off the required server requests asynchronously to the servers. As they
  /// return `progress` is called and the trips get added to TripKit's database. Also
  /// calls `completion` when all are done.
  ///
  /// - note: Calling this method will lock-in the departure time for "Leave now" queries.
  ///
  /// As trips get added, they get flagged with full, minimised or hidden visibility.
  /// Which depends on the standard defaults. Check `TKSettings` for setting
  /// those.
  ///
  /// - Parameters:
  ///   - request: The request specifying the query
  ///   - modes: The modes to enable. If set to `nil` then it'll use the modes as set in the user defaults (see `TKSettings` for more)
  ///   - classifier: Optional classifier to assign `TripGroup`'s `classification`
  ///   - progress: Optional progress callback executed when each request finished, with the number of completed requests passed to the block.
  ///   - completion: Callback executed when all requests have finished with the original request and, optionally, an error if all failed.
  /// - returns: The number of requests sent. This will match the number of times `progress` is called.
  @discardableResult
  public func multiFetchTrips(for request: TripRequest, modes: Set<String>? = nil, classifier: TKTripClassifier? = nil, progress: ((UInt) -> Void)? = nil, completion: @escaping (Result<Void, Error>) -> Void) -> UInt {
    return multiFetchTrips(request: request, modes: modes, classifier: classifier, progress: progress) { result in
      completion(result.map { _ in })
    }
  }
  
  private func multiFetchTrips(request: TKRouterRequestable, modes: Set<String>? = nil, classifier: TKTripClassifier? = nil, progress: ((UInt) -> Void)? = nil, completion: @escaping (Result<TripRequest, Error>) -> Void) -> UInt {
    let queue = DispatchQueue(label: "com.skedgo.TripKit.multi-fetch-worker")
    self.workerQueue = queue
    var count: UInt = 0
    queue.sync {
      do {
        count = try self.multiFetchTripsWorker(request: request, modes: modes, classifier: classifier, progress: progress, on: queue, completion: completion)
      } catch {
        self.handleError(error, callbackQueue: queue, completion: completion)
      }
    }
    return count
  }
    
  private func multiFetchTripsWorker(request: TKRouterRequestable, modes: Set<String>? = nil, classifier: TKTripClassifier? = nil, progress: ((UInt) -> Void)? = nil, on queue: DispatchQueue, completion: @escaping (Result<TripRequest, Error>) -> Void) throws -> UInt {
    
    let additional = try request.performAndWait(\.additional)
    let includesAllModes = additional.contains { $0.name == "allModes" }
    
    let enabledModes = try modes ?? request.performAndWait(\.modes)
    if includesAllModes {
      modeIdentifiers = enabledModes
      fetchTrips(for: request, bestOnly: false, additional: additional, callbackQueue: queue, completion: completion)
      return 1
    }
    
    guard !enabledModes.isEmpty else {
      throw RoutingError.invalidRequest("No modes enabled")
    }
    
    let groupedIdentifier = TKTransportMode.groupModeIdentifiers(enabledModes, includeGroupForAll: true)
    
    let tripRequest: TripRequest = try request.performAndWait {
      let tripRequest = $0.toTripRequest()
      try request.context?.save()
      return tripRequest
    }
    
    queue.async {
      self.cancelRequestsWorker()
      self.isActive = true
      
      for modeGroup in groupedIdentifier {
        if self.workers[modeGroup] != nil {
          continue
        }
        
        let worker = TKRouter(config: .userSettings())
        self.workers[modeGroup] = worker
        worker.server = self.server
        worker.config = self.config
        worker.failOnAnyError = self.failOnAnyError
        worker.modeIdentifiers = modeGroup
        
        // Hidden as we'll adjust the visibility in the completion block
        worker.fetchTrips(for: tripRequest, additional: additional, visibility: .hidden, callbackQueue: queue) { [weak self] result in
          guard let self = self else { return }
          
          self.finishedWorkers += 1
          progress?(self.finishedWorkers)
          
          switch result {
          case .failure(let error):
            self.handleMultiFetchResult(.failure(error), modes: worker.modeIdentifiers, request: tripRequest, completion: completion)
            
          case .success:
            // Classifiers will likely heavily read from the trips, so
            // we need to switch
            request.perform { _ in
              if modes == nil {
                // We get hidden modes here in the completion block
                // since they might have changed while waiting for results
                let hidden = TKSettings.hiddenModeIdentifiers
                tripRequest.adjustVisibility(hiddenIdentifiers: hidden)
              } else {
                tripRequest.adjustVisibility(hiddenIdentifiers: [])
              }
              
              // Updating classifications before making results visible
              if let classifier = classifier {
                tripRequest.updateTripGroupClassifications(using: classifier)
              }
              
              // Then back to worker queue to update internals
              queue.async {
                self.handleMultiFetchResult(result, modes: worker.modeIdentifiers, request: tripRequest, completion: completion)
              }
            }
          }
        }
      }
    }
    
    return UInt(groupedIdentifier.count)
  }
  
  private func handleMultiFetchResult(_ result: Result<Void, Error>, modes: Set<String>, request: TripRequest, completion: @escaping (Result<TripRequest, Error>) -> Void) {
    workers.removeValue(forKey: modes)
    
    if case .failure(let error) = result {
      self.lastWorkerError = error
    }
    
    if workers.isEmpty {
      request.perform { _ in
        // Only show an error if we found nothing, unless `failOnAnyError == true`
        if (self.failOnAnyError || request.trips.isEmpty), let error = self.lastWorkerError {
          completion(.failure(error))
        } else {
          completion(.success(request))
        }
      }
    }
  }
  
}

extension TripRequest {
  fileprivate func adjustVisibility(hiddenIdentifiers: Set<String>) {
    for group in tripGroups {
      let groupIdentifiers = group.usedModeIdentifiers
      if TKModeHelper.modesContain(hiddenIdentifiers, groupIdentifiers) {
        // if any mode is hidden, hide the whole group
        group.visibility = .hidden
      } else {
        group.visibility = .full
      }
    }
  }
}

#endif

// MARK: - Hitting API

public protocol TKRouterRequestable {
  var from: TKAPI.Location { get }
  var to: TKAPI.Location { get }
  var at: TKRoutingQueryTime { get }
  var modes: Set<String> { get }
  var additional: Set<URLQueryItem> { get }
  
#if canImport(CoreData)
  var context: NSManagedObjectContext? { get }
  
  func toTripRequest() -> TripRequest
#endif
  
}

fileprivate extension TKRouterRequestable {
#if canImport(CoreData)
  func toQuery() -> TKRoutingQuery<NSManagedObjectContext> {
    TKRoutingQuery(
      from: from,
      to: to,
      at: at,
      modes: modes,
      additional: additional,
      context: context
    )
  }
#else
  func toQuery() -> TKRoutingQuery<Never> {
    TKRoutingQuery(
      from: from,
      to: to,
      at: at,
      modes: modes,
      additional: additional
    )
  }
#endif
  
  func perform(_ block: @escaping (Self) -> Void) {
#if os(Linux)
    block(self)
#else
    if let context = context {
      context.perform {
        block(self)
      }
    } else {
      block(self)
    }
#endif
  }
  
  func performAndWait<R>(_ block: (Self) throws -> R) throws -> R {
#if os(Linux)
    return try block(self)
#else
    if let context = context {
      var result: R! = nil
      var blockError: Error? = nil
      context.performAndWait {
        do {
          result = try block(self)
        } catch {
          blockError = error
        }
      }
      if let blockError = blockError {
        throw blockError
      } else {
        return result
      }
    } else {
      return try block(self)
    }
#endif
  }
}

#if canImport(CoreData)

extension TKRoutingQuery: TKRouterRequestable where Context == NSManagedObjectContext {
  public func toTripRequest() -> TripRequest {
    guard let context = context else { preconditionFailure() }
    
    let timeType: TKTimeType
    let date: Date?
    switch at {
    case .leaveASAP:
      timeType = .leaveASAP
      date = nil
    case .leaveAfter(let time):
      timeType = .leaveAfter
      date = time
    case .arriveBy(let time):
      timeType = .arriveBefore
      date = time
    }
    
    return TripRequest.insert(
      from: TKNamedCoordinate(from),
      to: TKNamedCoordinate(to),
      for: date, timeType: timeType,
      into: context
    )
  }
}

extension TripRequest: TKRouterRequestable {
  public var context: NSManagedObjectContext? { managedObjectContext }
  public var from: TKAPI.Location { TKAPI.Location(annotation: fromLocation ?? .init(coordinate: .invalid)) }
  public var to: TKAPI.Location { TKAPI.Location(annotation: toLocation ?? .init(coordinate: .invalid)) }
  
  public var modes: Set<String> { TKSettings.enabledModeIdentifiers(applicableModeIdentifiers) }

  public var at: TKRoutingQueryTime {
    switch (type, departureTime, arrivalTime) {
    case (.arriveBefore, _, .some(let time)): return .arriveBy(time)
    case (.leaveAfter, .some(let time), _): return .leaveAfter(time)
    default: return .leaveASAP
    }
  }
  
  public var additional: Set<URLQueryItem> {
    let exclusionItems = (excludedStops ?? []).map { URLQueryItem(name: "avoidStops", value: $0) }
    if let additionalDefaults = TKRouter.defaultParameters {
      return Set(exclusionItems + additionalDefaults)
    } else {
      return Set(exclusionItems)
    }
  }
  
  public func toTripRequest() -> TripRequest { self }
}
#endif

extension TKRouter {
  
  public static func requestParameters(for request: TKRouterRequestable, modeIdentifiers: Set<String>?, additional: Set<URLQueryItem>?, config: TKAPIConfig?, bestOnly: Bool = false, includeAddress: Bool = true) -> [String: Any] {
    return Self.requestParameters(
      request: request.toQuery(),
      modeIdentifiers: modeIdentifiers,
      additional: additional,
      config: config ?? .userSettings(),
      bestOnly: bestOnly,
      includeAddress: includeAddress
    )
  }

  public static func urlRequest(for request: TKRouterRequestable, modes: Set<String>? = nil, includeAddress: Bool = false) throws -> URLRequest {
    return try Self.urlRequest(
      request: request.toQuery(),
      modes: modes,
      includeAddress: includeAddress,
      config: .userSettings()
    )
  }
  
  public static func routingRequestURL(for request: TKRouterRequestable, modes: Set<String>? = nil, includeAddress: Bool = true) -> String? {
    try? urlRequest(for: request, modes: modes, includeAddress: includeAddress).url?.absoluteString
  }
  
#if canImport(CoreData)

  private func fetchTrips(for request: TKRouterRequestable, bestOnly: Bool, additional: Set<URLQueryItem>?, visibility: TripGroup.Visibility = .full, callbackQueue: DispatchQueue = .main, completion: @escaping (Result<TripRequest, Error>) -> Void) {
    Task {
      self.isActive = true
      do {
        let response = try await TKRouter.fetchTripsResponse(
          for: request.toQuery(),
          modeIdentifiers: modeIdentifiers, // yes, not `request.modes`, as this might have been adjusted!
          bestOnly: bestOnly,
          additional: additional,
          config: self.config,
          server: self.server
        )
        
        try Task.checkCancellation()
        
        let tripRequest = request.toTripRequest()
        self.parse(response, for: tripRequest, visibility: visibility, callbackQueue: callbackQueue, completion: completion)
        
      } catch {
        self.handleError(error, callbackQueue: callbackQueue, completion: completion)
      }
      self.isActive = false
    }
  }
  
#endif
}


// MARK: - Handling response

extension TKAPI.Location {
  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
}

extension TKRouter {
  private func handleError<S>(_ error: Error, callbackQueue: DispatchQueue?, completion: @escaping (Result<S, Error>) -> Void) {
    // Ignore outdated request errors
    guard isActive else { return }
    
    isActive = false
    TKLog.debug("Request failed with error: \(error)")
    if let callbackQueue = callbackQueue {
      callbackQueue.async {
        completion(.failure(error))
      }
    } else {
      completion(.failure(error))
    }
  }
  
#if canImport(CoreData)
  
  private func parse(_ response: TKAPI.RoutingResponse, for request: TripRequest, visibility: TripGroup.Visibility, callbackQueue: DispatchQueue, completion: @escaping (Result<TripRequest, Error>) -> Void) {
    guard isActive, let context = request.managedObjectContext else { return }
    
    TKLog.verbose("Parsing \(request)")
    TKRoutingParser.add(response, to: request, merge: true, visibility: visibility) { _ in
      do {
        TKLog.verbose("Saving parsed result for \(request)")
        try context.save()
        callbackQueue.async {
          completion(.success(request))
        }
      } catch {
        assertionFailure("Error saving: \(error)")
        self.handleError(error, callbackQueue: callbackQueue, completion: completion)
      }
    }
  }
  
#endif
  
}
