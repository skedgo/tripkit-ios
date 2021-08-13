//
//  TKAvailabilityFetcher.swift
//  TripKit
//
//  Created by Adrian Schönig on 29.10.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

import TripKit

#if SWIFT_PACKAGE
import TripKitObjc
#endif

extension TKBuzzInfoProvider {
  
  public static func fetchVehicleAvailabilities(locationId: String, in region: TKRegion, start: Date? = nil, end: Date? = nil) -> Single<[TKAPI.CarAvailability]> {
    
    var paras: [String: Any] = [ "identifier": locationId, "region": region.name ]
    if let start = start {
      paras["start"] = ISO8601DateFormatter().string(from: start)
    }
    if let end = end {
      paras["end"] = ISO8601DateFormatter().string(from: end)
    }
    
    return TKServer.shared.rx
      .hit(TKAPI.LocationInfo.self, path: "locationInfo.json", parameters: paras, region: region)
      .map { _, _, model in
        model.carPod?.availabilities ?? []
      }
  }
  
  public static func fetchVehicleAvailabilities(locationId: String, in region: TKRegion, filter: Observable<(start: Date, end: Date?)>) -> Observable<[TKAPI.CarAvailability]> {
    
    // TODO: We could be smarter about this, cache the previous result and only
    //   query again, if we need new data.
    
    return filter
      .flatMapLatest { start, end in
        return fetchVehicleAvailabilities(locationId: locationId, in: region, start: start, end: end)
      }
    
  }
  
}
