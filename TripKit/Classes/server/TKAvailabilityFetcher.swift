//
//  TKAvailabilityFetcher.swift
//  TripKit
//
//  Created by Adrian Schönig on 29.10.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

public class TKAvailabilityFetcher: NSObject {
  private override init() {
    super.init()
  }
  
  public struct CarAvailability: Codable, Hashable {
    public let car: API.SharedCar
    public let availability: API.BookingAvailability
  }
  
  public static func fetchVehicleAvailabilities(locationId: String, in region: TKRegion) -> Single<[CarAvailability]> {
    #warning("FIXME: Hit backend!")
    return .just(TKAvailabilityFetcher.Response.fake.cars)
    
//    let paras: [String: Any] = [:]
//    return TKServer.shared.rx
//      .hit(.GET, path: "/availabilities", parameters: paras, region: region)
//      .asSingle()
//      .map { _, _, data -> [CarAvailability] in
//        guard let data = data else { return [] }
//        let decoder = JSONDecoder()
//        // This will need adjusting down the track (when using ISO8601)
//        decoder.dateDecodingStrategy = .secondsSince1970
//        return try decoder.decode(TKAvailabilityFetcher.Response.self, from: data).cars
//      }
  }
}

fileprivate extension TKAvailabilityFetcher {
  struct Response: Codable {
    let cars: [CarAvailability]
  }
}

extension TKAvailabilityFetcher.Response {
  fileprivate static var fake: TKAvailabilityFetcher.Response = {
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
    return try! decoder.decode(TKAvailabilityFetcher.Response.self, from: data)
  }()
}
