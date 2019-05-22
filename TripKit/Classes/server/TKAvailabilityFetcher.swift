//
//  TKAvailabilityFetcher.swift
//  TripKit
//
//  Created by Adrian Schönig on 29.10.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

extension TKBuzzInfoProvider {
  
  public static func fetchVehicleAvailabilities(locationId: String, in region: TKRegion, start: Date? = nil, end: Date? = nil) -> Single<[API.CarAvailability]> {
    
    var paras: [String: Any] = [ "identifier": locationId, "region": region.name ]
    if let start = start {
      paras["start"] = ISO8601DateFormatter().string(from: start)
    }
    if let end = end {
      paras["end"] = ISO8601DateFormatter().string(from: end)
    }
    
    return TKServer.shared.rx
      .hit(.GET, path: "locationInfo.json", parameters: paras, region: region)
      .map { _, _, data -> [API.CarAvailability] in
        guard let data = data else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let info = try decoder.decode(API.LocationInfo.self, from: data)
        return info.carPod?.availabilities ?? []
      }
  }
  
  public static func fetchVehicleAvailabilities(locationId: String, in region: TKRegion, filter: Observable<(start: Date, end: Date?)>) -> Observable<[API.CarAvailability]> {
    
    // TODO: We could be smarter about this, cache the previous result and only
    //   query again, if we need new data.
    
    return filter
      .flatMapLatest { start, end in
        return fetchVehicleAvailabilities(locationId: locationId, in: region, start: start, end: end)
      }
    
  }
  
}
