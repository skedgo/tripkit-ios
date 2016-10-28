//
//  TKOccupancy.swift
//  TripKit
//
//  Created by Adrian Schoenig on 17/10/16.
//
//

import Foundation

/// Representation of real-time occupancy information for public transport
public enum TKOccupancy : Int {
  case unknown = 0
  case empty
  case manySeatsAvailable
  case fewSeatsAvailable
  case standingRoomOnly
  case crushedStandingRoomOnly
  case full
  case notAcceptingPassengers
  
  var description: String? {
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
