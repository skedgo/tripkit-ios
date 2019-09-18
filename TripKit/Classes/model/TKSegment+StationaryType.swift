//
//  TKSegment+StationaryType.swift
//  TripKit
//
//  Created by Adrian Schönig on 19.03.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKSegment {
  public enum StationaryType: String {
    case parkingOnStreet = "stationary_parking-onstreet"
    case parkingOffStreet = "stationary_parking-offstreet"
    case wait = "stationary_wait"
    case transfer = "stationary_transfer"
    case vehicleCollect = "stationary_vehicle-collect"
    case vehicleReturn = "stationary_vehicle-return"
    case airportCheckIn = "stationary_airport-checkin"
    case airportCheckOut = "stationary_airport-checkout"
    case airportTransfer = "stationary_airport-transfer"
  }
  
  public var stationaryType: StationaryType? {
    StationaryType(rawValue: modeInfo?.identifier ?? "")
  }
}
