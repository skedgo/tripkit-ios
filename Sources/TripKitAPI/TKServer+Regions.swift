//
//  TKServer+Regions.swift
//  TripKit
//
//  Created by Adrian Schönig on 13/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

#if canImport(MapKit)
import MapKit
#endif

extension TKRegionManager {
  
  enum RegionError: Error {
    case invalidCustomBaseURL
  }
  
  /// Fetched the list of regions and updates `TKRegionManager`'s cache
  ///
  /// Equivalent to `updateRegions(forced:) async throws`, but ignores the error.
  ///
  /// Recommended to call from the application delegate.
  /// - Parameter forced: Set true to force overwriting the internal cache
  public func updateRegions(forced: Bool = false) {
    Task {
      try? await fetchRegions(forced: forced)
    }
  }

  @available(*, renamed: "requireRegions()")
  public func requireRegions(completion: @escaping (Result<Void, Error>) -> Void) {
    guard !hasRegions else {
      return completion(.success(()))
    }
    Task {
      do {
        try await fetchRegions(forced: false)
        completion(.success(()))
      } catch {
        completion(.failure(error))
      }
    }
  }
  
  @MainActor
  public func requireRegions() async throws {
    if !hasRegions {
      try await fetchRegions(forced: false)
    }
  }
  
  /// Fetched the list of regions and updates `TKRegionManager`'s cache
  ///
  /// Equivalent to `updateRegions(forced:)`.
  ///
  /// Recommended to call from the application delegate.
  /// - Parameter forced: Set true to force overwriting the internal cache
  @MainActor
  public func fetchRegions(forced: Bool) async throws {
    if fetchTask == nil || forced {
      fetchTask?.cancel()
      fetchTask = Task {
        try await self.fetchRegionsWorker(forced: forced)
      }
    }

    try await fetchTask?.value
  }
    
  @MainActor
  private func fetchRegionsWorker(forced: Bool) async throws {
    let regionsURL: URL
    if let customBaseURL = TKServer.customBaseURL {
      guard let url = URL(string: customBaseURL) else {
        throw RegionError.invalidCustomBaseURL
      }
      regionsURL = url.appendingPathComponent("regions.json")
    } else {
      regionsURL = URL(string: "https://api.tripgo.com/v1/regions.json")!
    }
    
    var paras: [String: Any] = ["v": 2]
    if !forced {
      paras["hashCode"] = regionsHash
    }
    
    let response = await TKServer.shared.hit(TKAPI.RegionsResponse.self, .POST, url: regionsURL, parameters: paras)
    try Task.checkCancellation()
    
    switch response.result {
    case .success(let model):
      updateRegions(from: model)
      if hasRegions {
        return
      } else {
        // let message = NSLocalizedString("Could not download supported regions from TripGo's server. Please try again later.", tableName: "Shared", bundle: .tripKit, comment: "Could not download supported regions warning.")
        // throw NSError(code: TKErrorCode.userError.rawValue, message: message)
        throw TKRegionParserError.fetchingRegionsFailed
      }
      
    case .failure(TKServer.ServerError.noData) where !forced:
      return // still up-to-date
    case .failure(let error):
      throw error
    }
  }
  
}

// MARK: - Convenience methods

#if canImport(MapKit)

extension TKRegionManager {
  @MainActor
  public func requireRegion(for coordinate: CLLocationCoordinate2D) async throws -> TKRegion {
    try await requireRegions()
    return self.region(containing: coordinate, coordinate)
  }

  @MainActor
  public func requireRegion(for coordinateRegion: MKCoordinateRegion) async throws -> TKRegion {
    try await requireRegions()
    return self.region(containing: coordinateRegion)
  }
}

#endif
