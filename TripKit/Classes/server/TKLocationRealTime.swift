//
//  TKLocationRealTime.swift
//  TripKit
//
//  Created by Adrian Schoenig on 8/08/2016.
//
//

import Foundation

import RxSwift

public enum TKLocationRealTime {
  
  public static func fetchLocationInfo(locationID: String, in region: TKRegion) -> Single<TKAPI.LocationInfo> {
    streamRealTime(identifier: locationID, in: region)
      .take(1)
      .asSingle()
  }

  @available(*, deprecated, message: "You should manage that yourself.")
  public static func streamRealTime(for location: TKNamedCoordinate, fetchOnlyOn: Observable<Bool>) -> Observable<TKAPI.LocationInfo> {
    return fetchOnlyOn
      .flatMapLatest { fetch -> Observable<TKAPI.LocationInfo> in
        if fetch {
          return streamRealTime(for: location)
        } else {
          return .empty()
        }
      }
  }
  
  public static func streamRealTime(for location: TKNamedCoordinate) -> Observable<TKAPI.LocationInfo> {
    return TKServer.shared.rx
      .requireRegion(location.coordinate)
      .asObservable()
      .flatMapLatest {
        streamRealTime(identifier: location.locationID, coordinate: location.coordinate, in: $0)
      }
  }
  
  private static func streamRealTime(identifier: String?, coordinate: CLLocationCoordinate2D = .invalid, in region: TKRegion) -> Observable<TKAPI.LocationInfo> {
    let paras: [String: Any]
    if let identifier = identifier {
      paras = [
        "region": region.name,
        "identifier": identifier,
      ]
    } else {
      paras = [
        "lat": coordinate.latitude,
        "lng": coordinate.longitude,
      ]
    }
    
    return TKServer.shared.rx
      .stream(.GET, path: "locationInfo.json", parameters: paras, region: region) { status, data in
        if case 400..<500 = status {
          return nil // Client-side errors; hitting again won't help
        }
        if let data = data,
           let info = try? JSONDecoder().decode(TKAPI.LocationInfo.self, from: data) {
          return info.hasRealTime ? .repeatIn(10) : nil
        } else {
          return .repeatIn(60) // Try again in a while
        }
      }
      .compactMap { status, _, data in
        guard let data = data else { return nil }
        return try? JSONDecoder().decode(TKAPI.LocationInfo.self, from: data)
      }
  }
  
}
