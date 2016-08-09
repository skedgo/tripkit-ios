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
  
  public static func rx_fetchRealTime(named: SGNamedCoordinate) -> Observable<LocationInformation> {
    
    return SVKServer.sharedInstance()
      .rx_requireRegion(named.coordinate)
      .flatMap { region -> Observable<LocationInformation> in
        var paras: [String: AnyObject] = [
          "realtime" : true
        ]
        if let identifier = named.locationID {
          paras["identifier"] = identifier
        } else {
          paras["lat"] = named.coordinate.latitude
          paras["lng"] = named.coordinate.longitude
        }
        
        return SVKServer.sharedInstance().rx_hit(.GET, path: "locationInfo.json", parameters: paras, region: region) { status, json in
          
            if case 400..<500 = status {
              return nil // Client-side errors; hitting again won't help
            }
          
            if let location = LocationInformation(response: json?.dictionaryObject) {
              return location.hasRealTime ? 30 : nil
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
