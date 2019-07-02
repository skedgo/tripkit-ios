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

  @available(*, deprecated, message: "You should manage that yourself.")
  public static func streamRealTime(for location: TKNamedCoordinate, fetchOnlyOn: Observable<Bool>) -> Observable<API.LocationInfo> {
    return fetchOnlyOn
      .flatMapLatest { fetch -> Observable<API.LocationInfo> in
        if fetch {
          return streamRealTime(for: location)
        } else {
          return .empty()
        }
      }
  }
  
  public static func streamRealTime(for location: TKNamedCoordinate) -> Observable<API.LocationInfo> {
    return TKServer.shared.rx
      .requireRegion(location.coordinate)
      .asObservable()
      .flatMapLatest { region -> Observable<API.LocationInfo> in

        let paras: [String: Any]
        if let identifier = location.locationID {
          paras = [
            "region": region.name,
            "identifier": identifier,
          ]
        } else {
          paras = [
            "lat": location.coordinate.latitude,
            "lng": location.coordinate.longitude,
          ]
        }
        
        return TKServer.shared.rx
          .stream(.GET, path: "locationInfo.json", parameters: paras, region: region) { status, data in
            if case 400..<500 = status {
              return nil // Client-side errors; hitting again won't help
            }
            if let data = data,
               let info = try? JSONDecoder().decode(API.LocationInfo.self, from: data) {
              return info.hasRealTime ? .repeatIn(10) : nil
            } else {
              return .repeatIn(60) // Try again in a while
            }
          }
          .compactMap { status, _, data in
            guard let data = data else { return nil }
            return try? JSONDecoder().decode(API.LocationInfo.self, from: data)
          }
      }
  }
  
}
