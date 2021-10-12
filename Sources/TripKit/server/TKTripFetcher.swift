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
  
  public static func downloadTrip(_ url: URL, identifier: String? = nil, into context: NSManagedObjectContext, completion: @escaping (Result<Trip, Error>) -> Void) {
    
    let identifier = identifier ?? String(url.absoluteString.hash)
    
    func withData(_ data: Data, shareURL: URL? = nil) {
      Self.parseTrip(from: data, into: context) { result in
        completion(result.map { trip in
          trip.shareURLString = trip.shareURLString ?? shareURL?.absoluteString
          trip.request.expandForFavorite = true
          return trip
        })
      }
    }
    
    downloadTripData(from: url, includeStops: true) { result in
      switch result {
      case let .success((.some(data), shareURL)):
        TKFileCache.save(identifier, data: data, directory: .documents)
        withData(data, shareURL: shareURL)
        
      case .success:
        // Download succeeded but was empty => failure
        if let cached = TKFileCache.read(identifier, directory: .documents) {
          withData(cached)
        } else {
          completion(.failure(FetcherError.serverError()))
        }

        
      case .failure(let error):
        if let cached = TKFileCache.read(identifier, directory: .documents) {
          withData(cached)
        
        } else {
          TKLog.info("Failed to download trip, and no copy in cache. Error: \(error)")
          completion(.failure(error))
        }
      }
    }
    
  }
  
  public static func update(_ trip: Trip, url: URL? = nil, aborter: @escaping ((URL) -> Bool) = { _ in false }, completion: @escaping (Result<(Trip, URL, didUpdate: Bool), Error>) -> Void) {
    let url = url ?? trip.updateURLString.flatMap( { URL(string: $0) })
    guard let updateURL = url else {
      completion(.failure(FetcherError.invalidURL))
      return
    }
    
    self.downloadTripData(from: updateURL, includeStops: false) { result in
      if aborter(updateURL) {
        return // no need to call completion block
      }
      
      switch result {
      case let .success((.some(data), _)):
        parseTrip(from: data, updating: trip) { result in
          completion(result.map { ($0, updateURL, true) })
        }
      case .success((.none, _)):
        completion(.success((trip, updateURL, false)))
      case let .failure(error):
        completion(.failure(error))
      }
    }
  }
  
  private static func downloadTripData(from url: URL, includeStops: Bool, completion: @escaping (Result<(Data?, shareURL: URL), Error>) -> Void) {
    
    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      completion(.failure(FetcherError.invalidURL))
      return assertionFailure()
    }
    
    switch components.scheme {
    case "file", "http", "https":
      break // supported out-of-the-box
    
    default:
      // turn app names into a HTTPS download
      components.scheme = "https"
    }

    guard let shareURL = components.url else {
      completion(.failure(FetcherError.invalidURL))
      return assertionFailure()
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
      completion(.failure(FetcherError.invalidURL))
      return assertionFailure()
    }
        
    TKServer.hit(url: url) { _, _, response in
      switch response {
      case .success(let data):
        completion(.success((data, shareURL: shareURL)))
      case .failure(TKServer.ServerError.noData):
        // Empty response, which is valid for updates
        completion(.success((nil, shareURL: shareURL)))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  private static func parseTrip(from data: Data, into context: NSManagedObjectContext, completion: @escaping (Result<Trip, Error>) -> Void) {
    let response: TKAPI.RoutingResponse
    do {
      response = try JSONDecoder().decode(TKAPI.RoutingResponse.self, from: data)
    } catch {
      completion(.failure(error))
      return
    }
      
    TKRoutingParser.add(response, into: context) { result in
      completion(Result {
        let request = try result.get()
        try context.save()
        request.preferredGroup = request.tripGroups.first
        request.preferredGroup?.adjustVisibleTrip()
        return try request.preferredTrip.orThrow(FetcherError.noTrip)
      })
    }
  }
  
  private static func parseTrip(from data: Data, updating trip: Trip, completion: @escaping (Result<Trip, Error>) -> Void) {
    let response: TKAPI.RoutingResponse
    do {
      response = try JSONDecoder().decode(TKAPI.RoutingResponse.self, from: data)
    } catch {
      completion(.failure(error))
      return
    }
    
    TKRoutingParser.update(trip, from: response, completion: completion)
  }
  
}

fileprivate extension Array where Element == URLQueryItem {
  mutating func addDefault(name: String, value: @autoclosure () -> String) {
    guard !contains(where: { $0.name == name }) else { return }
    append(.init(name: name, value: value()))
  }
}
