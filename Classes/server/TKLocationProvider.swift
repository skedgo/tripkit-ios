//
//  TKLocationProvider.swift
//  TripKit
//
//  Created by Adrian Schoenig on 18/5/17.
//
//

import Foundation
import CoreLocation

import Marshal
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
  public static func fetchLocations(center: CLLocationCoordinate2D, radius: CLLocationDistance, modes: [String]? = nil) -> Observable<[STKModeCoordinate]> {
    
    return SVKServer.shared.rx
      .requireRegion(center)
      .flatMap { region in
        TKLocationProvider.fetchLocations(center: center, radius: radius, modes: modes, in: region)
      }
  }
  
  public static func fetchLocations(center: CLLocationCoordinate2D, radius: CLLocationDistance, modes: [String]? = nil, in region: SVKRegion) -> Observable<[STKModeCoordinate]> {

    var paras: [String: Any] = [
      "lat": center.latitude,
      "lng": center.longitude,
      "radius": radius,
    ]
    paras["modes"] = modes
    
    return SVKServer.shared.rx
      .hit(.GET, path: "locations.json", parameters: paras, region: region)
      .map { _, response -> [STKModeCoordinate] in
        guard
          let marshaled = response as? MarshaledObject,
          let groups: [GroupedLocations] = try? marshaled.value(for: "groups")
        else {
          throw Error.serverReturnedBadFormat
        }
        
        return groups.reduce(mutating: []) { $0.append(contentsOf: $1.all) }
      }
    
  }
  
}

fileprivate struct GroupedLocations: Unmarshaling {
  let group: String
  let hashCode: Int
  let stops:      [STKStopCoordinate]
  let bikePods:   [TKBikePodLocation]
  let carPods:    [TKCarPodLocation]
  let carParks:   [TKCarParkLocation]
  let carRentals: [TKCarRentalLocation]
  
  var all: [STKModeCoordinate] {
    return stops    as [STKModeCoordinate]
      + bikePods    as [STKModeCoordinate]
      + carPods     as [STKModeCoordinate]
      + carParks    as [STKModeCoordinate]
      + carRentals  as [STKModeCoordinate]
  }
  
  // MARK: Unmarshaling
  
  init(object: MarshaledObject) throws {
    group       = try object.value(for: "key")
    hashCode    = try object.value(for: "hashCode")
    stops       = (try? object.value(for: "stops"))      ?? []
    bikePods    = (try? object.value(for: "bikePods"))   ?? []
    carPods     = (try? object.value(for: "carPods"))    ?? []
    carParks    = (try? object.value(for: "carParks"))   ?? []
    carRentals  = (try? object.value(for: "carRentals")) ?? []
  }
}
