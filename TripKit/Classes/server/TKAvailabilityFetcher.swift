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
  @available(iOS 10.0, *)
  public static func fetchVehicleAvailabilities(locationId: String, in region: TKRegion) -> Single<[API.CarAvailability]> {
    let paras: [String: Any] = [ "identifier": locationId, "region": region.name ]
    return TKServer.shared.rx
      .hit(.GET, path: "locationInfo.json", parameters: paras, region: region)
      .asSingle()
      .map { _, _, data -> [API.CarAvailability] in
        guard let data = data else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let info = try decoder.decode(API.LocationInfo.self, from: data)
        return info.carPod?.availabilities ?? []
      }
  }
}
