//
//  TKAPI+ViewHelpers.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 01.08.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

import TripKit

extension TKAPI.VehicleOccupancy {
  
  /// A small icon showing 4 people, where some of them are drawn in the "occupied color",
  /// depending on occupancy.
  ///
  /// - Parameter occupiedColor: Colour for occupied state, defaults to 'primary label' colour
  /// - Returns: Image or `nil` for `.unknown` occupancy
  func standingPeople(occupiedColor: TKColor? = nil) -> TKImage? {
    var standingCount: Int? {
      switch self {
      case .unknown: return nil
      case .empty, .manySeatsAvailable: return 1
      case .fewSeatsAvailable: return 2
      case .standingRoomOnly: return 3
      case .crushedStandingRoomOnly: return 3
      case .full, .notAcceptingPassengers: return 4
      }
    }
    
    let color = occupiedColor ?? .tkLabelPrimary
    return standingCount.map { TKUIStyleKit.imageOfOccupancyPeople(occupied: color, occupiedCount: CGFloat($0)) }
  }

}

extension TKAPI.Alert.Severity {
  
  public var textColor: UIColor {
    switch self {
    case .alert: return .tkLabelOnDark
    case .info: return .tkBackground
    case .warning: return .tkLabelOnLight
    }
  }
  
  public var backgroundColor: UIColor {
    switch self {
    case .alert: return .tkStateError
    case .warning: return .tkStateWarning
    case .info: return .tkLabelSecondary
    }
  }

  public var icon: UIImage {
    let fileName: String
    switch self {
    case .info, .warning:
      fileName = "icon-alert-yellow-high-res"
    case .alert:
      fileName = "icon-alert-red-high-res"
    }
    return TripKitUIBundle.imageNamed(fileName)
  }
  
}

extension TKAPI.VehicleTypeInfo {
  var localized: String {
    if let name = name { return name }
    
    switch (formFactor, propulsionType) {
    case (.bicycle, .electric),
         (.bicycle, .electricAssist): return Loc.VehicleTypeEBike
    case (.bicycle, _): return Loc.VehicleTypeBicycle
    case (.car, _): return Loc.VehicleTypeCar
    case (.scooter, _): return Loc.VehicleTypeKickScooter
    case (.moped, _): return Loc.VehicleTypeMotoScooter
    case (.other, _): return "Vehicle" // TODO: Localise
    }
  }
  
  var image: UIImage? {
    let imageName: String
    switch (formFactor, propulsionType) {
    case (.bicycle, .electric),
         (.bicycle, .electricAssist): imageName = "bicycle-electric"
    case (.bicycle, _): imageName = "bicycle"
    case (.car, _): imageName = "car"
    case (.scooter, _): imageName = "kickscooter"
    case (.moped, _): imageName = "motoscooter"
    case (.other, _): return nil
    }
    return TKStyleManager.image(forModeImageName: imageName)
  }
}

extension TKAPI.SharedVehicleInfo {
  
  var batteryText: String? {
    if let currentRange = currentRange {
      return MKDistanceFormatter().string(fromDistance: currentRange)
    } else if let batteryLevel = batteryLevel {
      return "\(batteryLevel)%"
    } else {
      return nil
    }
  }
}
