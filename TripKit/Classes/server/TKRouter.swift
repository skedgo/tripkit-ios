//
//  TKRouter.swift
//  TripKit-iOS
//
//  Created by Adrian Schönig on 01.11.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

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
  
  /// Optional server to use instead of `TKServer.shared`. Should only be used for testing or development.
  public var server: TKServer?

  /// Set to limit the modes. If not provided, modes according to `TKUserProfileHelper` will be used.
  public var modeIdentifiers: Set<String> = []

  private var isActive: Bool = false

  private var lastWorkerError: Error? = nil
  private var workers: [Set<String>: TKRouter] = [:]
  private var finishedWorkers: UInt = 0
  
  /// The main method to call to have the router calculate trips.
  /// - Parameters:
  ///   - request: An instance of a `TripRequest` which specifies what kind of trips should get calculated.
  ///   - completion: Block called when done, on success or failure
  public func fetchTrips(for request: TripRequest, additional: Set<URLQueryItem>? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
    guard !request.isDeleted else {
      let error = NSError(code: Int(kTKErrorTypeInternal), message: "Trip request deleted.")
      completion(.failure(error))
      return
    }
    
    return fetchTrips(for: request, bestOnly: false, additional: additional) {
      let result = $0.map { _ in }
      completion(result)
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
  /// modes according to `TKUserProfileHelper`.
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
  
  public func cancelRequests() {
    workers.map(\.value).forEach { $0.cancelRequests() }
    self.workers = [:]
    self.finishedWorkers = 0
    self.lastWorkerError = nil
    self.isActive = false
  }
}

// MARK: - Multi-fetch

extension TKRouter {
  
  /// Kicks off the required server requests asynchronously to the servers. As they
  /// return `progress` is called and the trips get added to TripKit's database. Also
  /// calls `completion` when all are done.
  ///
  /// - note: Calling this method will lock-in the departure time for "Leave now" queries.
  ///
  /// As trips get added, they get flagged with full, minimised or hidden visibility.
  /// Which depends on the standard defaults. Check `TKUserProfileHelper` for setting
  /// those.
  ///
  /// - Parameters:
  ///   - request: The request specifying the query
  ///   - modes: The modes to enable. If set to `nil` then it'll use the modes as set in the user defaults (see `TKUserProfileHelper` for more)
  ///   - classifier: Optional classifier to assign `TripGroup`'s `classification`
  ///   - progress: Optional progress callback executed when each request finished, with the number of completed requests passed to the block.
  ///   - completion: Callback executed when all requests have finished with the original request and, optionally, an error if all failed.
  /// - returns: The number of requests sent. This will match the number of times `progress` is called.
  public func multiFetchTrips(for query: RoutingQuery, classifier: TKTripClassifier? = nil, progress: ((UInt) -> Void)? = nil, completion: @escaping (Result<TripRequest, Error>) -> Void) -> UInt {
    return multiFetchTrips(request: query, classifier: classifier, progress: progress, completion: completion)
  }
  
  /// Kicks off the required server requests asynchronously to the servers. As they
  /// return `progress` is called and the trips get added to TripKit's database. Also
  /// calls `completion` when all are done.
  ///
  /// - note: Calling this method will lock-in the departure time for "Leave now" queries.
  ///
  /// As trips get added, they get flagged with full, minimised or hidden visibility.
  /// Which depends on the standard defaults. Check `TKUserProfileHelper` for setting
  /// those.
  ///
  /// - Parameters:
  ///   - request: The request specifying the query
  ///   - modes: The modes to enable. If set to `nil` then it'll use the modes as set in the user defaults (see `TKUserProfileHelper` for more)
  ///   - classifier: Optional classifier to assign `TripGroup`'s `classification`
  ///   - progress: Optional progress callback executed when each request finished, with the number of completed requests passed to the block.
  ///   - completion: Callback executed when all requests have finished with the original request and, optionally, an error if all failed.
  /// - returns: The number of requests sent. This will match the number of times `progress` is called.
  public func multiFetchTrips(for request: TripRequest, modes: Set<String>? = nil, classifier: TKTripClassifier? = nil, progress: ((UInt) -> Void)? = nil, completion: @escaping (Result<Void, Error>) -> Void) -> UInt {
    return multiFetchTrips(request: request, modes: modes, classifier: classifier, progress: progress) { result in
      completion(result.map { _ in })
    }
  }
  
  private func multiFetchTrips(request: TKRouterRequestable, modes: Set<String>? = nil, classifier: TKTripClassifier? = nil, progress: ((UInt) -> Void)? = nil, completion: @escaping (Result<TripRequest, Error>) -> Void) -> UInt {
    
    let includesAllModes = request.additional.contains { $0.name == "allModes" }
    if includesAllModes {
      fetchTrips(for: request, bestOnly: false, additional: nil, completion: completion)
      return 1
    }
    
    guard let context = request.context else {
      completion(.failure(RoutingError.invalidRequest("Could not access CoreData storage")))
      return 0
    }

    cancelRequests()
    self.isActive = true

    let enabledModes = modes ?? request.modes
    guard !enabledModes.isEmpty else {
      completion(.failure(RoutingError.invalidRequest("No modes enabled")))
      return 0
    }
    
    let groupedIdentifier = TKTransportModes.groupModeIdentifiers(enabledModes, includeGroupForAll: true)
    
    var tripRequest: TripRequest! = nil
    context.performAndWait {
      tripRequest = request.toTripRequest()
      do {
        try context.save()
      } catch {
        assertionFailure()
        return handleError(error, completion: completion)
      }
    }

    // we'll adjust the visibility in the completion block
    tripRequest.defaultVisibility = .hidden
    
    for modeGroup in groupedIdentifier {
      if self.workers[modeGroup] != nil {
        continue
      }
      
      let worker = TKRouter()
      workers[modeGroup] = worker
      worker.server = server
      worker.modeIdentifiers = modeGroup
      
      worker.fetchTrips(for: tripRequest, additional: request.additional) { [weak self] result in
        guard let self = self else { return }
        
        self.finishedWorkers += 1
        progress?(self.finishedWorkers)
        
        switch result {
        case .failure(let error):
          self.handleMultiFetchResult(.failure(error), modes: worker.modeIdentifiers, request: tripRequest, completion: completion)
          
        case .success:
          if modes == nil {
            // We get the minimized and hidden modes here in the completion block
            // since they might have changed while waiting for results
            let minimized = TKUserProfileHelper.minimizedModeIdentifiers
            let hidden = TKUserProfileHelper.hiddenModeIdentifiers
            tripRequest.adjustVisibility(forMinimizedModeIdentifiers: minimized, hiddenModeIdentifiers: hidden)
          } else {
            tripRequest.adjustVisibility(forMinimizedModeIdentifiers: [], hiddenModeIdentifiers: [])
          }
          
          // Updating classifications before making results visible
          if let classifier = classifier {
            tripRequest.updateTripGroupClassifications(using: classifier)
          }
          
          self.handleMultiFetchResult(result, modes: worker.modeIdentifiers, request: tripRequest, completion: completion)
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
      // Only show an error if we found nothing
      if request.trips.isEmpty, let error = self.lastWorkerError {
        completion(.failure(error))
      } else {
        completion(.success(request))
      }
    }
  }
  
}

extension TKTransportModes {
  
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
      } else if mode == TKTransportModeIdentifierFlight, modes.count > 1 {
        continue // don't add flights by themselves
      } else if mode == TKTransportModeIdentifierWalking || mode == TKTransportModeIdentifierWheelchair {
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
  var context: NSManagedObjectContext? { get }
  
  func toTripRequest() -> TripRequest
}

extension TKRouter.RoutingQuery: TKRouterRequestable {
  public func toTripRequest() -> TripRequest {
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
      into: context!
    )
  }
}

extension TripRequest: TKRouterRequestable {
  public var context: NSManagedObjectContext? { managedObjectContext }
  public var from: MKAnnotation { fromLocation }
  public var to: MKAnnotation { toLocation }
  
  public var modes: Set<String> {
    return Set(applicableModeIdentifiers())
      .subtracting(TKUserProfileHelper.hiddenModeIdentifiers)
    
  }

  public var at: TKShareHelper.QueryDetails.Time {
    switch (type, departureTime, arrivalTime) {
    case (.arriveBefore, _, .some(let time)): return .arriveBy(time)
    case (.leaveAfter, .some(let time), _): return .leaveAfter(time)
    default: return .leaveASAP
    }
  }
  
  public var additional: Set<URLQueryItem> {
    let exclusionItems = excludedStops.map { URLQueryItem(name: "avoidStops", value: $0) }
    return Set(exclusionItems)
  }
  
  public func toTripRequest() -> TripRequest { self }
}

extension TKRouter {
  
  public static func routingRequestURL(for request: TKRouterRequestable, modes: Set<String>? = nil) -> String? {
    let paras = requestParameters(for: request, modeIdentifiers: modes, additional: nil)
    let baseURL = TKServer.shared.fallbackBaseURL()
    let fullURL = baseURL.appendingPathComponent("routing.json")
    let request = TKServer.getRequestWithSkedGoHTTPHeaders(for: fullURL, paras: paras)
    return request.url?.absoluteString
  }
  
  private static func requestParameters(for request: TKRouterRequestable, modeIdentifiers: Set<String>?, additional: Set<URLQueryItem>?, bestOnly: Bool = false) -> [String: Any] {
    var paras = TKSettings.config
    let modes = modeIdentifiers ?? request.modes
    paras["modes"] = modes.sorted()
    paras["from"] = TKParserHelper.requestString(for: request.from)
    paras["to"] = TKParserHelper.requestString(for: request.to)
    
    switch request.at {
    case .arriveBy(let arrival):
      paras["arriveBefore"] = arrival.timeIntervalSince1970
    case .leaveAfter(let departure):
      paras["departAfter"] = departure.timeIntervalSince1970
    case .leaveASAP:
      paras["departAfter"] = Date().timeIntervalSince1970
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
          return list.map(\.value)
        }
      }
    paras.merge(fromQueryItems) { old, _ in old }
    return paras
  }
  
  private func fetchTrips(for request: TKRouterRequestable, bestOnly: Bool, additional: Set<URLQueryItem>?, completion: @escaping (Result<TripRequest, Error>) -> Void) {

    // Mark as active early, to make sure we pass on errors
    self.isActive = true
    
    // sanity checks
    guard request.from.coordinate.isValid else {
      return handleError(NSError(code: Int(kTKServerErrorTypeUser), message: "Start location could not be determined. Please try again or select manually."), completion: completion)
    }
    guard request.to.coordinate.isValid else {
      return handleError(NSError(code: Int(kTKServerErrorTypeUser), message: "End location could not be determined. Please try again or select manually."), completion: completion)
    }
    
    let server = self.server ?? .shared
    server.requireRegions { [weak self] error in
      guard let self = self else { return }
      
      if let error = error {
        return self.handleError(error, completion: completion)
      }
      
      // we are guaranteed to have regions
      guard let region = TKRegionManager.shared.localRegions(start: request.from.coordinate, end: request.to.coordinate).first else {
        return self.handleError(
          NSError(code: 1001, // matches server
                  message: Loc.RoutingBetweenTheseLocationsIsNotYetSupported),
          completion: completion)
      }
      
      let paras = Self.requestParameters(
        for: request,
        modeIdentifiers: self.modeIdentifiers,
        additional: additional,
        bestOnly: bestOnly
      )
      server.hitSkedGo(
        withMethod: "GET",
        path: "routing.json",
        parameters: paras,
        region: region,
        callbackOnMain: false,
        success: { [weak self] _, response, _ in
          guard let self = self else { return }
          let tripRequest = request.toTripRequest()
          self.parseJSON(response, for: tripRequest, completion: completion)
          
        }, failure: { [weak self] error in
          self?.handleError(error, completion: completion)
        }
      )
    }
  }
  
}


// MARK: - Handling response

extension TKRouter {

  private func handleError(_ error: Error, completion: @escaping (Result<TripRequest, Error>) -> Void) {
    // Ignore outdated request errors
    guard isActive else { return }
    
    isActive = false
    TKLog.debug("TKRouter") { "Request failed with error: \(error)"}
    completion(.failure(error))
  }
  
  private func parseJSON(_ json: Any?, for request: TripRequest, completion: @escaping (Result<TripRequest, Error>) -> Void) {
    guard isActive, let context = request.managedObjectContext else { return }
    
    if let error = TKError.error(fromJSON: json, statusCode: 200) {
      return handleError(error, completion: completion)
    }
    
    guard let json = json as? [AnyHashable: Any] else {
      return handleError(NSError(code: Int(kTKErrorTypeInternal), message: "Invalid response received from server. Please try again."), completion: completion)
    }

    context.perform { [weak self] in
      guard let self = self else { return }
      
      // make sure that the parent context is saved
      do {
        try context.save()
        
        TKLog.verbose("TKRouter") { "Parsing \(request)" }
        let parser = TKRoutingParser(tripKitContext: context)
        parser.parseAndAddResult(json, for: request, merging: true)
        
        TKLog.verbose("TKRouter") { "Saving parsed result for \(request)" }
        try context.save()
        
        completion(.success(request))

      } catch {
        assertionFailure("Error saving: \(error)")
        self.handleError(error, completion: completion)
      }

    }
  }
  
}
