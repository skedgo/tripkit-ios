//
//  LatestAPIModel.swift
//  TripKit
//
//  Created by Adrian Schönig on 11/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKAPI {
  
  public struct LatestResponse: Codable {
    public let services: [LatestService]
  }
  
  public struct LatestService: Codable {
    public let code: String
    
    @OptionalISO8601OrSecondsSince1970 public var startTime: Date?
    @OptionalISO8601OrSecondsSince1970 public var endTime: Date?
    
    public let primaryVehicle: Vehicle?
    @DefaultEmptyArray public var alternativeVehicles: [Vehicle]
    @DefaultEmptyArray public var alerts: [Alert]
    
    @DefaultEmptyArray public var stops: [LatestStop]

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
  
  public struct LatestStop: Codable {
    public let stopCode: String
    @OptionalISO8601OrSecondsSince1970 public var arrival: Date?
    @OptionalISO8601OrSecondsSince1970 public var departure: Date?
  }
  
}
