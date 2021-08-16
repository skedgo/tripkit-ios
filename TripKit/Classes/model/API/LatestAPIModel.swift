//
//  LatestAPIModel.swift
//  TripKit
//
//  Created by Adrian Schönig on 11/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKAPI {
  
  struct LatestResponse: Codable {
    let services: [LatestService]
  }
  
  struct LatestService: Codable {
    let code: String
    
    @OptionalISO8601OrSecondsSince1970 public var startTime: Date?
    @OptionalISO8601OrSecondsSince1970 public var endTime: Date?
    
    let primaryVehicle: Vehicle?
    @DefaultEmptyArray var alternativeVehicles: [Vehicle]
    @DefaultEmptyArray var alerts: [Alert]
    
    @DefaultEmptyArray var stops: [LatestStop]

    private enum CodingKeys: String, CodingKey {
      case code = "serviceTripID"
      case startTime
      case endTime
      case stops
      case primaryVehicle = "realtimeVehicle"
      case alternativeVehicles = "realtimeVehicleAlternatives"
      case alerts
    }
  }
  
  struct LatestStop: Codable {
    let stopCode: String
    @OptionalISO8601OrSecondsSince1970 var arrival: Date?
    @OptionalISO8601OrSecondsSince1970 var departure: Date?
  }
  
}
