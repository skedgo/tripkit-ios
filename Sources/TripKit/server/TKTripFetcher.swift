//
//  TKTripFetcher.swift
//  TripKit
//
//  Created by Adrian Schönig on 6/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import CoreData

public enum TKTripFetcher {
  
  enum FetcherError: Error {
    case invalidURL
    case noContext
    case noTrip
    case serverError(String? = nil)
  }
  
  public static func downloadTrip(_ url: URL, identifier: String? = nil, into context: NSManagedObjectContext = TripKit.shared.tripKitContext) async throws -> Trip {
    
    let identifier = identifier ?? String(url.absoluteString.hash)
    
    func tripWithData(_ data: Data, shareURL: URL? = nil) async throws -> Trip {
      let trip = try await Self.parseTrip(from: data, into: context)
      trip.shareURLString = trip.shareURLString ?? shareURL?.absoluteString
      trip.request.expandForFavorite = true
      return trip
    }
    
    do {
      let tripData = try await downloadTripData(from: url, includeStops: true)
      switch tripData {
      case let (.some(data), shareURL):
        TKFileCache.save(identifier, data: data, directory: .documents)
        return try await tripWithData(data, shareURL: shareURL)
        
      default:
        // Download succeeded but was empty => failure
        if let cached = TKFileCache.read(identifier, directory: .documents) {
          return try await tripWithData(cached)
        } else {
          throw FetcherError.serverError()
        }
      }
    } catch {
      if let cached = TKFileCache.read(identifier, directory: .documents) {
        return try await tripWithData(cached)
      
      } else {
        TKLog.info("Failed to download trip, and no copy in cache. Error: \(error)")
        throw error
      }
    }
    
  }
  
  /// Perform one-off real-time update of the provided trip
  ///
  /// No need to call this if `trip.wantsRealTimeUpdates == false`. It'd just complete immediately.
  ///
  /// - Parameter trip: The trip to update
  ///
  /// - returns: One-off callback with the update. Note that the `Trip` object returned will always be the same object provided to the method, i.e., trips are updated in-place.
  public static func update(_ trip: Trip, url: URL? = nil, aborter: @escaping ((URL) -> Bool) = { _ in false }) async throws -> (Trip, URL?, didUpdate: Bool)? {
    guard trip.wantsRealTimeUpdates else {
      TKLog.debug("Don't bother calling this for trips that don't want updates")
      return (trip, nil, false)
    }
    
    let url = url ?? trip.updateURLString.flatMap( { URL(string: $0) })
    guard let updateURL = url else {
      throw FetcherError.invalidURL
    }
    
    let tripData = try await downloadTripData(from: updateURL, includeStops: false)
    if aborter(updateURL) {
      return nil // no need to return anything
    }
      
    switch tripData {
    case let (.some(data), _):
      let trip = try await parseTrip(from: data, updating: trip)
      return (trip, updateURL, true)
    case (.none, _):
      return (trip, updateURL, false)
    }
  }
  
  private static func downloadTripData(from url: URL, includeStops: Bool) async throws -> (Data?, shareURL: URL) {
    
    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      assertionFailure()
      throw FetcherError.invalidURL
    }
    
    switch components.scheme {
    case "file", "http", "https":
      break // supported out-of-the-box
    
    default:
      // turn app names into a HTTPS download
      components.scheme = "https"
    }

    guard let shareURL = components.url else {
      assertionFailure()
      throw FetcherError.invalidURL
    }

    // fill in some default parameters that don't relate to trip properties
    // but rather how it's output -- at least, where the URL doesn't have them
    let config = TKSettings.Config()
    var queryItems = components.queryItems ?? []
    queryItems.addDefault(name: "v", value: String(config.version))
    queryItems.addDefault(name: "unit", value: config.distanceUnit.rawValue)
    queryItems.addDefault(name: "bsb", value: config.bookingSandbox ? "true" : "false")
    
    if includeStops {
      queryItems.addDefault(name: "includeStops", value: "true")
    }
    
    guard let url = components.url else {
      assertionFailure()
      throw FetcherError.invalidURL
    }
    
    let response = await TKServer.shared.hit(url: url)
    switch response.result {
    case .success(let data):
      return (data, shareURL: shareURL)
    case .failure(TKServer.ServerError.noData):
      // Empty response, which is valid for updates
      return (nil, shareURL: shareURL)
    case .failure(let error):
      throw error
    }
  }
  
  private static func parseTrip(from data: Data, into context: NSManagedObjectContext) async throws -> Trip {
    let response = try JSONDecoder().decode(TKAPI.RoutingResponse.self, from: data)
    let request = try await TKRoutingParser.add(response, into: context)
    #warning("TODO: Tell parser to save")
    try context.save()
    request.preferredGroup = request.tripGroups.first
    request.preferredGroup?.adjustVisibleTrip()
    return try request.preferredTrip.orThrow(FetcherError.noTrip)
  }
  
  private static func parseTrip(from data: Data, updating trip: Trip) async throws -> Trip {
    let response = try JSONDecoder().decode(TKAPI.RoutingResponse.self, from: data)
    return try await TKRoutingParser.update(trip, from: response)
  }
  
}

fileprivate extension Array where Element == URLQueryItem {
  mutating func addDefault(name: String, value: @autoclosure () -> String) {
    guard !contains(where: { $0.name == name }) else { return }
    append(.init(name: name, value: value()))
  }
}
