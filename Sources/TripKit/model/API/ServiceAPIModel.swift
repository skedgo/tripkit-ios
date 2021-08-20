//
//  Service.swift
//  TripKit
//
//  Created by Adrian Schoenig on 22.09.17.
//

import Foundation

extension TKAPI {

  public struct ServiceResponse: Codable {
    public let error: String?
    public let shapes: [SegmentShape]?
    public let modeInfo: TKModeInfo?
    
    // real-time information
    public let realTimeStatus: RealTimeStatus?
    public let primaryVehicle: Vehicle?
    @DefaultEmptyArray public var alternativeVehicles: [Vehicle]
    @DefaultEmptyArray public var alerts: [Alert]

    private enum CodingKeys: String, CodingKey {
      case error
      case shapes
      case modeInfo
      case realTimeStatus
      case primaryVehicle = "realtimeVehicle"
      case alternativeVehicles = "realtimeVehicleAlternatives"
      case alerts
    }
  }
  
  public struct Departure: Codable, Hashable {
    
    // information about the service
    public let serviceTripID: String
    public let operatorID: String?
    
    public let operatorName: String
    public let number: String?
    public let name: String?
    public let direction: String?
    public let color: RGBColor?
    public let modeInfo: TKModeInfo

    @DefaultEmptyArray public var alertHashCodes: [Int]
    public let bicycleAccessible: Bool?
    public let wheelchairAccessible: Bool?
    
    // real-time information
    public let realTimeStatus: RealTimeStatus?
    @OptionalISO8601OrSecondsSince1970 public var realTimeDeparture: Date?
    @OptionalISO8601OrSecondsSince1970 public var realTimeArrival: Date?
    public let primaryVehicle: Vehicle?
    @DefaultEmptyArray public var alternativeVehicles: [Vehicle]

    // static information about the departure
    public let frequency: Int?
    public let searchString: String?
    @OptionalISO8601OrSecondsSince1970 public var startTime: Date?
    @OptionalISO8601OrSecondsSince1970 public var endTime: Date?
    public let endStopCode: String?
    
    private enum CodingKeys: String, CodingKey {
      case serviceTripID
      case operatorID
      
      case operatorName = "operator"
      case color = "serviceColor"
      case number = "serviceNumber"
      case name = "serviceName"
      case direction = "serviceDirection"
      case modeInfo
      
      case alertHashCodes
      case bicycleAccessible
      case wheelchairAccessible
      
      case searchString
      case frequency
      
      case realTimeStatus
      case realTimeDeparture
      case realTimeArrival
      case primaryVehicle = "realtimeVehicle"
      case alternativeVehicles = "realtimeVehicleAlternatives"
      
      case startTime
      case endTime
      case endStopCode
    }
  }
  
}

