//
//  API+ViewHelpers.swift
//  TripKit
//
//  Created by Adrian Schönig on 01.08.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKAPI.VehicleOccupancy {
  
  /// - Parameter all: Nested vehicle components
  /// - Returns: Average occupancy in the provided nested list of vehicle components, `nil` if no occupancy found.
  public static func average(in all: [[TKAPI.VehicleComponents]]?) -> (TKAPI.VehicleOccupancy, title: String)? {
    guard let all = all else { return nil }
    
    let ocupancies = all
      .flatMap { $0 }
      .compactMap { ($0.occupancy != nil && $0.occupancy != .unknown) ? ($0.occupancy!, $0.occupancyText) : nil }
    if ocupancies.isEmpty {
      return nil
    } else if ocupancies.count == 1, let first = ocupancies.first {
      return (first.0, first.1 ?? first.0.localizedTitle)
    }
    
    if ocupancies.contains(where: { $0.1 != nil }), let best = ocupancies.min(by: { $0.0.intValue < $1.0.intValue } ) {
      // If any has a title, we pick the best (as we aren't guaranteed to have
      // an appropriate title for the average value)
      return (best.0, best.1 ?? best.0.localizedTitle)
      
    } else if let average = average(in: ocupancies.map(\.0)) {
      return (average, average.localizedTitle)

    } else {
      return nil
    }
  }
  
  /// - Parameter all: List of occupancies
  /// - Returns: Average occupancy, `nil` if list was empty
  private static func average(in all: [TKAPI.VehicleOccupancy]) -> TKAPI.VehicleOccupancy? {
    guard !all.isEmpty else { return nil }
    let sum = all.reduce(0) { $0 + $1.intValue }
    return TKAPI.VehicleOccupancy(intValue: sum / all.count)
  }
  
  public var color: TKColor? {
    switch self {
    case .unknown: return nil
    case .empty, .manySeatsAvailable: return #colorLiteral(red: 0, green: 0.7333984971, blue: 0.4438126683, alpha: 1)
    case .fewSeatsAvailable: return #colorLiteral(red: 1, green: 0.7553820014, blue: 0, alpha: 1)
    case .standingRoomOnly, .crushedStandingRoomOnly: return #colorLiteral(red: 1, green: 0.6531761289, blue: 0, alpha: 1)
    case .full, .notAcceptingPassengers: return#colorLiteral(red: 1, green: 0.3921365738, blue: 0.34667629, alpha: 1)
    }
  }
  
  public var localizedTitle: String {
    switch self {
    case .unknown: return Loc.Unknown
    case .empty: return NSLocalizedString("Empty", tableName: "TripKit", bundle: .tripKit, comment: "As in 'this bus/train is empty'")
    case .manySeatsAvailable: return NSLocalizedString("Many seats available", tableName: "TripKit", bundle: .tripKit, comment: "As in 'this bus/train has many seats available'")
    case .fewSeatsAvailable: return NSLocalizedString("Few seats available", tableName: "TripKit", bundle: .tripKit, comment: "As in 'this bus/train has few seats available'")
    case .standingRoomOnly: return NSLocalizedString("Standing room only", tableName: "TripKit", bundle: .tripKit, comment: "As in 'this bus/train is fairly full and has standing room only'")
    case .crushedStandingRoomOnly: return NSLocalizedString("Limited standing room only", tableName: "TripKit", bundle: .tripKit, comment: "As in 'this bus/train is so full, there's only limited standing room'")
    case .full: return NSLocalizedString("Full", tableName: "TripKit", bundle: .tripKit, comment: "As in 'this bus/train is full and likely can't accept further passengers'")
    case .notAcceptingPassengers: return NSLocalizedString("Not accepting passengers", tableName: "TripKit", bundle: .tripKit, comment: "As in 'this bus/train is full and definitely not accepting further passengers'")
    }
  }

}

extension TKAPI.VehicleTypeInfo {
  public var localized: String {
    if let name = name { return name }
    
    switch (formFactor, propulsionType) {
    case (.bicycle, .electric),
      (.bicycle, .electricAssist): return Loc.VehicleTypeEBike
    case (.bicycle, _): return Loc.VehicleTypeBicycle
    case (.car, _): return Loc.VehicleTypeCar
    case (.scooter, _): return Loc.VehicleTypeKickScooter
    case (.moped, _): return Loc.VehicleTypeMotoScooter
    case (.other, _): return Loc.Vehicle
    }
  }
  
  public var image: TKImage? {
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
  
  public var batteryText: String? {
    if let currentRange = currentRange {
      return MKDistanceFormatter().string(fromDistance: currentRange)
    } else if let batteryLevel = batteryLevel {
      return "\(batteryLevel)%"
    } else {
      return nil
    }
  }
  
  public var batteryImage: TKImage? {
    if let level = batteryLevel {
      switch level {
      case ..<12: return .iconBattery0
      case ..<37: return .iconBattery25
      case ..<62: return .iconBattery50
      case ..<87: return .iconBattery75
      default:    return .iconBattery100
      }
    } else if currentRange != nil {
      return .iconBattery
    } else {
      return nil
    }
  }
  
}
