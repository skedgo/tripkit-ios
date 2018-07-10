//
//  Service.swift
//  TripKit
//
//  Created by Adrian Schoenig on 22.09.17.
//

import Foundation

extension API {

  public struct Departure: Codable, Equatable {
    
    // information about the service
    let serviceTripID: String
    let operatorID: String
    
    let operatorName: String
    let number: String?
    let name: String?
    let direction: String?
    let color: RGBColor?
    let modeInfo: TKModeInfo

    let alertHashCodes: [Int]?
    let bicycleAccessible: Bool?
    let wheelchairAccessible: Bool?
    
    let realTimeStatus: RealTimeStatus?
    let primaryVehicle: Vehicle?
    let alternativeVehicles: [Vehicle]?

    // information about the departure
    let frequency: Int?
    let searchString: String?
    let startTime: TimeInterval?
    let endTime: TimeInterval?
    let endStopCode: String?
    
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
      case primaryVehicle = "realtimeVehicle"
      case alternativeVehicles = "realtimeVehicleAlternatives"
      
      case startTime
      case endTime
      case endStopCode
    }
  }
  
}

