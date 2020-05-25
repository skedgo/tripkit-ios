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
    
    let components = all.flatMap { $0 }
    if components.isEmpty {
      return nil
    } else if components.count == 1, let component = components.first {
      let occupancy = component.occupancy ?? .unknown
      return occupancy != .unknown
        ? (occupancy, component.occupancyText ?? occupancy.localizedTitle)
        : nil
    }
    
    if components.contains(where: { $0.occupancyText != nil }),
      let best = components.min(by: { $0.occupancy?.intValue ?? 0 < $1.occupancy?.intValue ?? 0 } ) {
      // If any has a title, we pick the best (as we aren't guaranteed to have
      // an appropriate title for the average value)
      return (best, best.localizedTitle)
      
    } else if let average = average(in: components.compactMap(\.occupancy)) {
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
    case .unknown: return NSLocalizedString("Unknown", comment: "")
    case .empty: return NSLocalizedString("Empty", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "As in 'this bus/train is empty'")
    case .manySeatsAvailable: return NSLocalizedString("Many seats available", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "As in 'this bus/train has many seats available'")
    case .fewSeatsAvailable: return NSLocalizedString("Few seats available", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "As in 'this bus/train has few seats available'")
    case .standingRoomOnly: return NSLocalizedString("Standing room only", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "As in 'this bus/train is fairly full and has standing room only'")
    case .crushedStandingRoomOnly: return NSLocalizedString("Limited standing room only", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "As in 'this bus/train is so full, there's only limited standing room'")
    case .full: return NSLocalizedString("Full", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "As in 'this bus/train is full and likely can't accept further passengers'")
    case .notAcceptingPassengers: return NSLocalizedString("Not accepting passengers", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "As in 'this bus/train is full and definitely not accepting further passengers'")
    }
  }

}

