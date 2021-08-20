//
//  TKLocationProvider.swift
//  TripKit
//
//  Created by Adrian Schoenig on 18/5/17.
//
//

import Foundation
import CoreLocation

import RxSwift

import TripKit

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
  public static func fetchLocations(center: CLLocationCoordinate2D, radius: CLLocationDistance, limit: Int = 100, modes: [String]? = nil, strictModeMatch: Bool = true) -> Single<[TKModeCoordinate]> {
    
    return TKRegionManager.shared.rx
      .requireRegion(center)
      .flatMap { region in
        TKLocationProvider.fetchLocations(
          center: center,
          radius: radius,
          limit: limit,
          modes: modes,
          strictModeMatch: strictModeMatch,
          in: region
        )
      }
  }
  
  public static func fetchLocations(center: CLLocationCoordinate2D, radius: CLLocationDistance, limit: Int = 100, modes: [String]? = nil, strictModeMatch: Bool = true, in region: TKRegion) -> Single<[TKModeCoordinate]> {

    guard region != .international else {
      return Single.just([])
    }
    
    var paras: [String: Any] = [
      "lat": center.latitude,
      "lng": center.longitude,
      "radius": Int(radius),
      "limit": limit,
      "strictModeMatch": strictModeMatch
    ]
    paras["modes"] = modes
    
    return TKServer.shared.rx
      .hit(TKAPI.LocationsResponse.self, path: "locations.json", parameters: paras, region: region)
      .map { _, _, model in
        model.groups.reduce(into: []) { $0.append(contentsOf: $1.all) }
      }
  }
  
}
