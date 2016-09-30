//
//  TKLocationRealTime.swift
//  Pods
//
//  Created by Adrian Schoenig on 8/08/2016.
//
//

import Foundation

import RxSwift
import SwiftyJSON

import SGCoreKit

public enum TKLocationRealTime {

  public static func fetchRealTimeInfo(for location: SGNamedCoordinate, fetchOnlyOn: Observable<Bool>) -> Observable<LocationInformation> {
    return fetchOnlyOn
      .flatMapLatest { fetch -> Observable<LocationInformation> in
        if fetch {
          return fetchRealTime(for: location)
        } else {
          return Observable.empty()
        }
      }
  }
  
  public static func fetchRealTime(for location: SGNamedCoordinate) -> Observable<LocationInformation> {
    return SVKServer.sharedInstance().rx
      .requireRegion(location.coordinate)
      .flatMap { region -> Observable<LocationInformation> in
        var paras: [String: Any] = [
          "realtime" : true
        ]
        
        if let identifier = location.locationID {
          paras["identifier"] = identifier
        } else {
          paras["lat"] = location.coordinate.latitude
          paras["lng"] = location.coordinate.longitude
        }
        
        return SVKServer.sharedInstance().rx
          .hit(.GET, path: "locationInfo.json", parameters: paras, region: region) { status, json in
            if case 400..<500 = status {
              return nil // Client-side errors; hitting again won't help
            }
          
            if let location = LocationInformation(response: json?.dictionaryObject) {
              return location.hasRealTime ? 10 : nil
            } else {
              return 60 // Try again in a while
            }
          }
          .map { status, json in
            return LocationInformation(response: json?.dictionaryObject)
          }
          .filter { $0 != nil }
          .map { $0! }
      }
  }
  
}
