//
//  TKLocationRealTime.swift
//  TripKit
//
//  Created by Adrian Schoenig on 8/08/2016.
//
//

import Foundation

import RxSwift
import Marshal



public enum TKLocationRealTime {

  public static func fetchRealTimeInfo(for location: SGKNamedCoordinate, fetchOnlyOn: Observable<Bool>) -> Observable<TKLocationInfo> {
    return fetchOnlyOn
      .flatMapLatest { fetch -> Observable<TKLocationInfo> in
        if fetch {
          return fetchRealTime(for: location)
        } else {
          return Observable.empty()
        }
      }
  }
  
  public static func fetchRealTime(for location: SGKNamedCoordinate) -> Observable<TKLocationInfo> {
    return SVKServer.shared.rx
      .requireRegion(location.coordinate)
      .flatMap { region -> Observable<TKLocationInfo> in
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
        
        return SVKServer.shared.rx
          .hit(.GET, path: "locationInfo.json", parameters: paras, region: region) { status, response in
            if case 400..<500 = status {
              return nil // Client-side errors; hitting again won't help
            }
          
            if let json = response as? [String: Any],
               let location = try? TKLocationInfo(object: json) {
              return location.hasRealTime ? 10 : nil
            } else {
              return 60 // Try again in a while
            }
          }
          .map { status, response in
            guard let json = response as? [String: Any] else { return nil }
            return try? TKLocationInfo(object: json)
          }
          .filter { $0 != nil }
          .map { $0! }
      }
  }
  
}
