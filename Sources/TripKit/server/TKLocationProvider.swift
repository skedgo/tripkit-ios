//
//  TKLocationProvider.swift
//  TripKit
//
//  Created by Adrian Schoenig on 18/5/17.
//
//

#if canImport(CoreLocation)

import Foundation
import CoreLocation

public enum TKLocationProvider {
  
  public enum Error: Swift.Error {
    case serverReturnedBadFormat
  }
  
  /// Fetches locations that are within the provided circle
  ///
  /// The observable can error out in cases where the circle
  /// is outside supported regions, or where the server could
  /// not be reached or returned an error.
  ///
  /// - Parameters:
  ///   - center: Centre coordinate of circle
  ///   - radius: Radius of circle in metres
  ///   - limit: Maximum number of locations to fetch, defaults to 100
  ///   - modes: Modes for which to fetch locations. If not provided, will use all.
  ///   - strictModeMatch: Should `modes` be treated strictly, or should related results also be returned?
  /// - Returns: Observable of fetched locations; always returns empty array for international region; can error out
  public static func fetchLocations(center: CLLocationCoordinate2D, radius: CLLocationDistance, limit: Int = 100, modes: [String]? = nil, strictModeMatch: Bool = true) async throws -> [TKNamedCoordinate] {
    
    let region = try await TKRegionManager.shared.requireRegion(for: center)
    return try await TKLocationProvider.fetchLocations(
      center: center,
      radius: radius,
      limit: limit,
      modes: modes,
      strictModeMatch: strictModeMatch,
      in: region
    )
  }
  
  public static func fetchLocations(center: CLLocationCoordinate2D, radius: CLLocationDistance, limit: Int = 100, modes: [String]? = nil, strictModeMatch: Bool = true, in region: TKRegion) async throws -> [TKNamedCoordinate] {

    guard region != .international else {
      return []
    }
    
    var paras: [String: Any] = [
      "lat": center.latitude,
      "lng": center.longitude,
      "radius": Int(radius),
      "limit": limit,
      "strictModeMatch": strictModeMatch
    ]
    paras["modes"] = modes
    let model = try await TKServer.shared.hit(TKAPI.LocationsResponse.self, path: "locations.json", parameters: paras, region: region).result.get()
    return model.groups.reduce(into: []) { $0.append(contentsOf: $1.all) }
  }
  
}

#endif
