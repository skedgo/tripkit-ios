//
//  TKRouter.swift
//  TripKit-iOS
//
//  Created by Adrian Schönig on 01.11.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

#if canImport(CoreData)

import MapKit
import CoreData

#endif

/// A TKRouter calculates trips for routing requests, it talks to TripGo's `routing.json` API.
@objc
public class TKRouter: NSObject {
  public enum RoutingError: Error, LocalizedError {
    case invalidRequest(String)
    case noTripFound
    
    public var errorDescription: String? {
      switch self {
      case .invalidRequest(let text): return text
      case .noTripFound: return Loc.NoRoutesFound
      }
    }
  }
  
  public struct RoutingQuery {
    public let from: MKAnnotation
    public let to: MKAnnotation
    public var at: TKShareHelper.QueryDetails.Time = .leaveASAP
    public let modes: Set<String>
    public var additional: Set<URLQueryItem> = []
    public var context: NSManagedObjectContext?

    public init(from: MKAnnotation, to: MKAnnotation, at time: TKShareHelper.QueryDetails.Time = .leaveASAP, modes: Set<String>, additional: Set<URLQueryItem> = [], context: NSManagedObjectContext) {
      self.from = from
      self.to = to
      self.at = time
      self.modes = modes
      self.additional = additional
      self.context = context
    }
  }
  
  /// Optional server to use instead of `TKServer.shared`.
  public var server: TKServer?
  
  /// Optional configuration parameters to use instead of `TKSettings.Config.fromUserDefaults()`.
  public var config: TKSettings.Config?

  /// Set to limit the modes. If not provided, modes according to `TKSettings` will be used.
  public var modeIdentifiers: Set<String> = []
  
  /// A `TKRouter` might turn a routing request into multiple server requests. If some of these fail
  /// but others return trips, the default behaviour is to return the trips that were found without returning
  /// an error. Set this to `true` to always return an error if any of the requests fail, even if some trips were
  /// found by other requests.
  public var failOnAnyError: Bool = false

  private var isActive: Bool = false

  private var lastWorkerError: Error? = nil
  private var workers: [Set<String>: TKRouter] = [:]
  private var finishedWorkers: UInt = 0
  private var workerQueue: DispatchQueue?
  
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
  public func fetchTrips(for query: RoutingQuery, completion: @escaping (Result<TripRequest, Error>) -> Void) {
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
  
  public func cancelRequests() {
    if let queue = workerQueue {
      queue.async(execute: cancelRequestsWorker)
    } else {
      cancelRequestsWorker()
    }
  }
  
  private func cancelRequestsWorker() {
    workers.map(\.value).forEach { $0.cancelRequests() }
    self.workers = [:]
    self.finishedWorkers = 0
    self.lastWorkerError = nil
    self.isActive = false
  }
}

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
  public func multiFetchTrips(for query: RoutingQuery, classifier: TKTripClassifier? = nil) async throws -> TripRequest {
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
  public func multiFetchTrips(for query: RoutingQuery, classifier: TKTripClassifier? = nil, progress: ((UInt) -> Void)? = nil, completion: @escaping (Result<TripRequest, Error>) -> Void) -> UInt {
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
    
    let includesAllModes = try request.performAndWait { $0.additional.contains { $0.name == "allModes" } }
    
    if includesAllModes {
      modeIdentifiers = try modes ?? request.performAndWait(\.modes)
      fetchTrips(for: request, bestOnly: false, additional: nil, callbackQueue: queue, completion: completion)
      return 1
    }
    
    let enabledModes = try modes ?? request.performAndWait(\.modes)
    guard !enabledModes.isEmpty else {
      throw RoutingError.invalidRequest("No modes enabled")
    }
    
    let groupedIdentifier = TKTransportMode.groupModeIdentifiers(enabledModes, includeGroupForAll: true)
    
    let tripRequest: TripRequest = try request.performAndWait {
      let tripRequest = $0.toTripRequest()
      try request.context?.save()
      return tripRequest
    }
    
    let additional = try request.performAndWait(\.additional)
    
    queue.async {
      self.cancelRequestsWorker()
      self.isActive = true
      
      for modeGroup in groupedIdentifier {
        if self.workers[modeGroup] != nil {
          continue
        }
        
        let worker = TKRouter()
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

extension TKTransportMode {
  
  /// Groups the mode identifiers
  /// - Parameters:
  ///   - modes: A set of all the identifiers to be grouped
  ///   - includeGroupForAll: If an extra group which has all the identifiers should be added
  /// - Returns: A set of a set of mode identifiers
  static func groupModeIdentifiers(_ modes: Set<String>, includeGroupForAll: Bool) -> Set<Set<String>> {
    var result: Set<Set<String>> = []
    var processedModes: Set<String> = []
    var includesWalkOnly = false
    for mode in modes {
      if processedModes.contains(mode) {
        continue // added already, e.g., via implied modes
      } else if mode == TKTransportMode.flight.modeIdentifier, modes.count > 1 {
        continue // don't add flights by themselves
      } else if mode == TKTransportMode.walking.modeIdentifier || mode == TKTransportMode.wheelchair.modeIdentifier {
        includesWalkOnly = true
      }
      
      var group: Set<String> = [mode]
      group.formUnion(TKRegionManager.shared.impliedModes(byModeIdentifer: mode))
      
      // see if we can merge this into an existing group
      let intersectionWithProcessed = processedModes.intersection(group)
      if intersectionWithProcessed.isEmpty {
        result.insert(group)
      } else {
        for existing in result {
          let intersectionWithCurrent = existing.intersection(group)
          if !intersectionWithCurrent.isEmpty {
            result.remove(existing)
            result.insert(existing.union(group))
            break
          }
        }
      }
      
      processedModes.formUnion(group)
    }
    
    if includeGroupForAll, result.count > 1 + (includesWalkOnly ? 1 : 0) {
      result.insert(modes)
    }
    
    return result
  }
}

// MARK: - Hitting API

public protocol TKRouterRequestable {
  var from: MKAnnotation { get }
  var to: MKAnnotation { get }
  var at: TKShareHelper.QueryDetails.Time { get }
  var modes: Set<String> { get }
  var additional: Set<URLQueryItem> { get }
  
#if canImport(CoreData)
  var context: NSManagedObjectContext? { get }
  
  func toTripRequest() -> TripRequest
#endif
  
}

fileprivate extension TKRouterRequestable {
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

extension TKRouter.RoutingQuery: TKRouterRequestable {
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
      from: from,
      to: to,
      for: date, timeType: timeType,
      into: context
    )
  }
}

extension TripRequest: TKRouterRequestable {
  public var context: NSManagedObjectContext? { managedObjectContext }
  public var from: MKAnnotation { fromLocation ?? .init(coordinate: .invalid) }
  public var to: MKAnnotation { toLocation ?? .init(coordinate: .invalid) }
  
  public var modes: Set<String> { TKSettings.enabledModeIdentifiers(applicableModeIdentifiers) }

  public var at: TKShareHelper.QueryDetails.Time {
    switch (type, departureTime, arrivalTime) {
    case (.arriveBefore, _, .some(let time)): return .arriveBy(time)
    case (.leaveAfter, .some(let time), _): return .leaveAfter(time)
    default: return .leaveASAP
    }
  }
  
  public var additional: Set<URLQueryItem> {
    let exclusionItems = (excludedStops ?? []).map { URLQueryItem(name: "avoidStops", value: $0) }
    return Set(exclusionItems)
  }
  
  public func toTripRequest() -> TripRequest { self }
}
#endif

extension TKRouter {
  
  public static func routingRequestURL(for request: TKRouterRequestable, modes: Set<String>? = nil) -> String? {
    let paras = requestParameters(for: request, modeIdentifiers: modes, additional: nil, config: nil)
    let baseURL = TKServer.fallbackBaseURL
    let fullURL = baseURL.appendingPathComponent("routing.json")
    let request = try? TKServer.shared.GETRequestWithSkedGoHTTPHeaders(for: fullURL, paras: paras)
    return request?.url?.absoluteString
  }
  
  static func requestParameters(for request: TKRouterRequestable, modeIdentifiers: Set<String>?, additional: Set<URLQueryItem>?, config: TKSettings.Config?, bestOnly: Bool = false) -> [String: Any] {
    var paras = (config ?? .userSettings()).paras
    let modes = modeIdentifiers ?? request.modes
    paras["modes"] = modes.sorted()
    paras["from"] = TKParserHelper.requestString(for: request.from)
    paras["to"] = TKParserHelper.requestString(for: request.to)
    
    switch request.at {
    case .arriveBy(let arrival):
      paras["arriveBefore"] = Int(arrival.timeIntervalSince1970)
    case .leaveAfter(let departure):
      paras["departAfter"] = Int(departure.timeIntervalSince1970)
    case .leaveASAP:
      paras["departAfter"] = Int(Date().timeIntervalSince1970)
    }
    
    if bestOnly {
      paras["bestOnly"] = true
      paras["includeStops"] = true
    }
    
    let additionalItems = additional ?? request.additional
    let fromQueryItems = Dictionary(grouping: additionalItems, by: \.name)
      .compactMapValues { list -> Any? in
        if list.count == 1, let first = list.first {
          return first.value
        } else {
          return list.compactMap(\.value)
        }
      }
    paras.merge(fromQueryItems) { old, _ in old }
    return paras
  }
  
#if canImport(CoreData)

  private func fetchTrips(for request: TKRouterRequestable, bestOnly: Bool, additional: Set<URLQueryItem>?, visibility: TripGroup.Visibility = .full, callbackQueue: DispatchQueue = .main, completion: @escaping (Result<TripRequest, Error>) -> Void) {
    fetchTripsResponse(for: request, bestOnly: bestOnly, additional: additional, callbackQueue: callbackQueue) { [weak self] result in
      request.perform { [weak self] _ in
        guard let self = self else { return }
        
        switch result {
        case .success(let response):
          let tripRequest = request.toTripRequest()
          self.parse(response, for: tripRequest, visibility: visibility, callbackQueue: callbackQueue, completion: completion)
          
        case .failure(let error):
          // Do NOT `handleError` again, as that's already called by
          // `fetchTripsResponse`, which marks this router as inactive,
          // and calling it again will mean nothing happens.
          completion(.failure(error))
        }
      }
    }
  }
  
#endif
  
  /// Alternative method to get the API response for fetching trips, without parsing them into a `Trip`
  func fetchTripsResponse(for request: TKRouterRequestable, bestOnly: Bool, additional: Set<URLQueryItem>?, callbackQueue: DispatchQueue? = nil, completion: @escaping (Result<TKAPI.RoutingResponse, Error>) -> Void) {

    // Mark as active early, to make sure we pass on errors
    self.isActive = true
    
    // sanity checks
    guard request.from.coordinate.isValid else {
      return handleError(NSError(code: TKErrorCode.userError.rawValue, message: "Start location could not be determined. Please try again or select manually."), callbackQueue: callbackQueue, completion: completion)
    }
    guard request.to.coordinate.isValid else {
      return handleError(NSError(code: TKErrorCode.userError.rawValue, message: "End location could not be determined. Please try again or select manually."), callbackQueue: callbackQueue, completion: completion)
    }
    
    TKRegionManager.shared.requireRegions { [weak self] regionsResult in
      request.perform { [weak self] _ in
        guard let self = self else { return }
        
        let region: TKRegion?
        if self.server is TKRoutingServer {
          // Fine to proceed without checking region as we're just hitting
          // the base URL anyway and can rely on server errors instead.
          // This allows hitting the server with different API keys without
          // having to update `TKRegionManager`.
          region = nil
          
        } else {
          if case .failure(let error) = regionsResult {
            return self.handleError(error, callbackQueue: callbackQueue, completion: completion)
          }

          // we are guaranteed to have regions
          guard let localRegion = TKRegionManager.shared.localRegions(start: request.from.coordinate, end: request.to.coordinate).first else {
            return self.handleError(
              NSError(code: 1001, // matches server
                      message: Loc.RoutingBetweenTheseLocationsIsNotYetSupported),
              callbackQueue: callbackQueue,
              completion: completion)
          }
          region = localRegion
        }
        
        let paras = Self.requestParameters(
          for: request,
          modeIdentifiers: self.modeIdentifiers,
          additional: additional,
          config: self.config,
          bestOnly: bestOnly
        )
        
        let server = self.server ?? .shared
        server.hit(TKAPI.RoutingResponse.self,
                   path: "routing.json",
                   parameters: paras,
                   region: region,
                   callbackOnMain: false
        ) { [weak self] _, _, result in
            switch result {
            case .success(let success):
              completion(.success(success))
            case .failure(let error):
              // For consistency, all errors from this method should go through
              // `handleError`
              self?.handleError(error, callbackQueue: callbackQueue, completion: completion)
            }
        }
      }
    }
  }
  
}


// MARK: - Handling response

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
