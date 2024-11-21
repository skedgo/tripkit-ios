//
//  TKRouter.swift
//  TripKit
//
//  Created by Adrian Schönig on 20/11/2024.
//

import Foundation
#if os(Linux)
import FoundationNetworking
#endif


/// A TKRouter calculates trips for routing requests, it talks to TripGo's `routing.json` API.
public class TKRouter: NSObject {
  public enum RoutingError: Error {
    case invalidRequest(String)
    case noTripFound
    case startLocationNotDetermined
    case endLocationNotDetermined
    case routingNotSupported
  }
  
  /// Optional server to use instead of `TKServer.shared`.
  public var server: TKServer?
  
  /// Optional configuration parameters to use
  public var config: TKAPIConfig
  
  /// Set to limit the modes. If not provided, modes according to `TKSettings` will be used.
  public var modeIdentifiers: Set<String> = []
  
  /// A `TKRouter` might turn a routing request into multiple server requests. If some of these fail
  /// but others return trips, the default behaviour is to return the trips that were found without returning
  /// an error. Set this to `true` to always return an error if any of the requests fail, even if some trips were
  /// found by other requests.
  public var failOnAnyError: Bool = false
  
  public /*private(set)*/ var isActive: Bool = false
  
  public /*private*/ var lastWorkerError: Error? = nil
  public /*private*/ var workers: [Set<String>: TKRouter] = [:]
  public /*private*/ var finishedWorkers: UInt = 0
  public /*private*/ var workerQueue: DispatchQueue?
  
  public init(config: TKAPIConfig) {
    self.config = config
    super.init()
  }
  
  public func cancelRequests() {
    if let queue = workerQueue {
      queue.async(execute: cancelRequestsWorker)
    } else {
      cancelRequestsWorker()
    }
  }
  
  public /*private*/  func cancelRequestsWorker() {
    workers.map(\.value).forEach { $0.cancelRequests() }
    self.workers = [:]
    self.finishedWorkers = 0
    self.lastWorkerError = nil
    self.isActive = false
  }
}



// MARK: - Multi-fetch

extension TKRouter {
  
  public static func multiFetchTripResponses<C>(request: TKRoutingQuery<C>, config: TKAPIConfig, server: TKServer? = nil) async throws -> [TKAPI.RoutingResponse] {
    let includesAllModes = request.additional.contains { $0.name == "allModes" }
    if includesAllModes {
      let response = try await Self.fetchTripsResponse(
        for: request,
        modeIdentifiers: request.modes,
        bestOnly: false,
        additional: request.additional,
        config: config,
        server: server
      )
      return [response]

    } else {
      let groupedIdentifier = TKTransportMode.groupModeIdentifiers(request.modes, includeGroupForAll: true)
      guard !groupedIdentifier.isEmpty else {
        throw RoutingError.invalidRequest("No modes enabled")
      }

      return try await withThrowingTaskGroup(of: TKAPI.RoutingResponse.self) { group in
        for modeGroup in groupedIdentifier {
          _ = group.addTaskUnlessCancelled {
            try await Self.fetchTripsResponse(
              for: request,
              modeIdentifiers: modeGroup,
              bestOnly: false,
              additional: request.additional,
              config: config,
              server: server
            )
          }
        }
        
        var responses: [TKAPI.RoutingResponse] = []
        for try await response in group {
          responses.append(response)
        }
        return responses
      }
    }
  }
  
}

// MARK: - Worker

extension TKRouter {
  
  public static func urlRequest<C>(request: TKRoutingQuery<C>, modes: Set<String>? = nil, includeAddress: Bool = false, config: TKAPIConfig) throws -> URLRequest {
    let paras = requestParameters(
      request: request,
      modeIdentifiers: modes,
      additional: nil,
      config: config,
      includeAddress: includeAddress
    )
    let baseURL = TKServer.fallbackBaseURL
    let fullURL = baseURL.appendingPathComponent("routing.json")
    return try TKServer.shared.GETRequestWithSkedGoHTTPHeaders(for: fullURL, paras: paras)
  }
  
  public static func routingRequestURL<C>(request: TKRoutingQuery<C>, modes: Set<String>? = nil, includeAddress: Bool = true, config: TKAPIConfig) -> String? {
    try? urlRequest(request: request, modes: modes, includeAddress: includeAddress, config: config).url?.absoluteString
  }
  
  public static func requestParameters<C>(request: TKRoutingQuery<C>, modeIdentifiers: Set<String>?, additional: Set<URLQueryItem>?, config: TKAPIConfig, bestOnly: Bool = false, includeAddress: Bool = true) -> [String: Any] {
    var paras = config.paras
    let modes = modeIdentifiers ?? request.modes
    paras["modes"] = modes.sorted()
    paras["from"] = TKRoutingQuery<Never>.requestString(for: request.from, includeAddress: includeAddress)
    paras["to"] = TKRoutingQuery<Never>.requestString(for: request.to, includeAddress: includeAddress)
    
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
  
  /// Alternative method to get the API response for fetching trips, without parsing them into a `Trip`
  public static func fetchTripsResponse<C>(for request: TKRoutingQuery<C>, modeIdentifiers: Set<String>, bestOnly: Bool, additional: Set<URLQueryItem>?, config: TKAPIConfig, server: TKServer? = nil) async throws -> TKAPI.RoutingResponse {

    // sanity checks
    guard request.from.isValid else {
      throw RoutingError.startLocationNotDetermined
    }
    guard request.to.isValid else {
      throw RoutingError.endLocationNotDetermined
    }
    
    try await TKRegionManager.shared.requireRegions()
    try Task.checkCancellation()
      
    let region: TKRegion?
    if server is TKRoutingServer {
      // Fine to proceed without checking region as we're just hitting
      // the base URL anyway and can rely on server errors instead.
      // This allows hitting the server with different API keys without
      // having to update `TKRegionManager`.
      region = nil
      
    } else {

      // we are guaranteed to have regions. Do we support the query?
      guard
        let localRegion = TKRegionManager.shared.localRegions(
          start: (latitude: request.from.latitude, longitude: request.from.longitude),
          end: (latitude: request.to.latitude, longitude: request.to.longitude)
        ).first
      else {
        throw RoutingError.routingNotSupported
      }
      region = localRegion
    }
    
    let paras = Self.requestParameters(
      request: request,
      modeIdentifiers: modeIdentifiers,
      additional: additional,
      config: config,
      bestOnly: bestOnly
    )
    
    let server = server ?? .shared
    let response = await server.hit(
      TKAPI.RoutingResponse.self,
      path: "routing.json",
      parameters: paras,
      region: region
    )
    return try response.result.get()
  }
  
}

// MARK: - Internals

extension TKTransportMode {
  
  /// Groups the mode identifiers
  /// - Parameters:
  ///   - modes: A set of all the identifiers to be grouped
  ///   - includeGroupForAll: If an extra group which has all the identifiers should be added
  /// - Returns: A set of a set of mode identifiers
  public static func groupModeIdentifiers(_ modes: Set<String>, includeGroupForAll: Bool) -> Set<Set<String>> {
    var result: Set<Set<String>> = []
    var processedModes: Set<String> = []
    var schoolBuses: Set<String> = []
    var includesWalkOnly = false
    
    for mode in modes {
      if processedModes.contains(mode) {
        continue // added already, e.g., via implied modes
      } else if mode == TKTransportMode.flight.modeIdentifier, modes.count > 1 {
        continue // don't add flights by themselves
      } else if mode == TKTransportMode.walking.modeIdentifier || mode == TKTransportMode.wheelchair.modeIdentifier {
        includesWalkOnly = true
      } else if mode.hasPrefix(TKTransportMode.schoolBuses.modeIdentifier) {
        schoolBuses.insert(mode)
        processedModes.insert(mode)
        continue
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
    
    if !schoolBuses.isEmpty {
      result.insert(schoolBuses)
    }
    
    if includeGroupForAll, result.count > 1 + (includesWalkOnly ? 1 : 0) {
      result.insert(modes)
    }
    
    return result
  }
}
