//
//  Service.swift
//  TripKit
//
//  Created by Adrian Schoenig on 22.09.17.
//

import Foundation

extension API {

  public struct Departure: Codable, Hashable {
    
    // information about the service
    public let serviceTripID: String
    public let operatorID: String
    
    public let operatorName: String
    public let number: String?
    public let name: String?
    public let direction: String?
    public let color: RGBColor?
    public let modeInfo: TKModeInfo

    public let alertHashCodes: [Int]?
    public let bicycleAccessible: Bool?
    public let wheelchairAccessible: Bool?
    
    // real-time information
    public let realTimeStatus: RealTimeStatus?
    public let realTimeDeparture: TimeInterval?
    public let realTimeArrival: TimeInterval?
    public let primaryVehicle: Vehicle?
    public let alternativeVehicles: [Vehicle]?

    // static information about the departure
    public let frequency: Int?
    public let searchString: String?
    public let startTime: TimeInterval?
    public let endTime: TimeInterval?
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

