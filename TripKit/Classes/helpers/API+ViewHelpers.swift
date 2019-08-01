//
//  API+ViewHelpers.swift
//  TripKit
//
//  Created by Adrian Schönig on 01.08.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension API.VehicleOccupancy {
  
  public static func average(in all: [[API.VehicleComponents]]?) -> API.VehicleOccupancy? {
    let occupancies = (all ?? [])
      .reduce(into: []) { $0.append(contentsOf: $1) }
      .compactMap { $0.occupancy }
    if occupancies.isEmpty {
      return nil
    } else if occupancies.count == 1 {
      return occupancies[0]
    }
    
    return average(in: occupancies)
  }
  
  public static func average(in all: [API.VehicleOccupancy]) -> API.VehicleOccupancy {
    let sum = all.reduce(0) { $0 + $1.intValue }
    return API.VehicleOccupancy(intValue: sum / all.count)
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
  
  public var localizedTitle: String? {
    switch self {
    case .unknown: return nil
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

