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

public enum TKLocationProvider {
  
  enum Error: Swift.Error {
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
  ///   - modes: Modes for which to fetch locations. If not provided, will use all.
  /// - Returns: Observable of fetched locations; can error out
  public static func fetchLocations(center: CLLocationCoordinate2D, radius: CLLocationDistance, modes: [String]? = nil) -> Single<[STKModeCoordinate]> {
    
    return SVKServer.shared.rx
      .requireRegion(center)
      .flatMap { region in
        TKLocationProvider.fetchLocations(center: center, radius: radius, modes: modes, in: region)
      }
      .asSingle()
  }
  
  public static func fetchLocations(center: CLLocationCoordinate2D, radius: CLLocationDistance, modes: [String]? = nil, in region: SVKRegion) -> Single<[STKModeCoordinate]> {

    var paras: [String: Any] = [
      "lat": center.latitude,
      "lng": center.longitude,
      "radius": radius,
    ]
    paras["modes"] = modes
    
    return SVKServer.shared.rx
      .hit(.GET, path: "locations.json", parameters: paras, region: region)
      .map { _, data -> [STKModeCoordinate] in
        let decoder = JSONDecoder()
        guard
          let data = data,
          let response = try? decoder.decode(API.LocationsResponse.self, from: data)
        else {
          throw Error.serverReturnedBadFormat
        }
        
        return response.groups.reduce(into: []) { $0.append(contentsOf: $1.all) }
      }
    .asSingle()
    
  }
  
}
