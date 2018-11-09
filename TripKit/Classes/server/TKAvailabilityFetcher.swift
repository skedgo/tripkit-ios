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
    
    //    return .just(TKBuzzInfoProvider.AvailabilityResponse.fake.cars)
    
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

fileprivate extension TKBuzzInfoProvider {
  struct AvailabilityResponse: Codable {
    let cars: [API.CarAvailability]
  }
}

extension TKBuzzInfoProvider.AvailabilityResponse {
  fileprivate static var fake: TKBuzzInfoProvider.AvailabilityResponse = {
    let now = Date().timeIntervalSince1970
    let end1 = now  + TimeInterval.random(in: (1...5)) * 3600
    let end2 = end1 + TimeInterval.random(in: (3...10)) * 3600

    let fake = """
    {
      "cars": [
        {
          "car": {
            "identifier": "CAR1",
            "name": "Moritz",
            "description": "Renault Zoe"
          },
          "availability": {
            "lastUpdated": \(now),
            "intervals": [
              {
                "end": \(end1),
                "status": "AVAILABLE"
              },
              {
                "start": \(end1),
                "end": \(end2),
                "status": "NOT_AVAILABLE"
              },
              {
                "start": \(end2),
                "status": "AVAILABLE"
              },
            ]
          }
        },
        {
          "car": {
            "identifier": "CAR2",
            "name": "Franz",
            "description": "Nissan Leaf"
          },
          "availability": {
            "lastUpdated": \(now),
            "intervals": [
              {
                "end": \(end1),
                "status": "NOT_AVAILABLE"
              },
              {
                "start": \(end1),
                "end": \(end2),
                "status": "AVAILABLE"
              },
              {
                "start": \(end2),
                "status": "UNKNOWN"
              },
            ]
          }
        },        
      ]
    }
    """
    let data = fake.data(using: .utf8)!
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970
    return try! decoder.decode(TKBuzzInfoProvider.AvailabilityResponse.self, from: data)
  }()
}
