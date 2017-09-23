//
//  BaseAPIModels.swift
//  TripKit
//
//  Created by Adrian Schoenig on 22.09.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension API {
  
  public struct Alert: Codable {
    
    public enum Severity: String, Codable {
      case info = "info"
      case warning = "warning"
      case alert = "alert"
    }
    
    let hashCode: Int
    let severity: Severity
    let title: String
    let text: String?
    let url: URL?
    
    let remoteIcon: URL?
    let location: Location?
    let startTime: TimeInterval?
    let endTime: TimeInterval?
    
    // FIXME: Add action again
  }
  
  public struct Location: Codable {
    let lat: CLLocationDegrees
    let lng: CLLocationDegrees
    let bearing: CLLocationDirection?
    let name: String?
    let address: String?
  }
  
  public struct ModeInfo: Codable {
    let alt: String
    let identifier: String?
    let localIcon: String?
    let remoteIconURL: URL? // removeIcon
    let remoteDarkIconURL: URL? // removeDarkIcon
    let descriptor: String?
    let color: RGBColor?
  }
  
  public enum RealTimeStatus: String, Codable {
    case capable    = "CAPABLE"
    case incapable  = "INCAPABLE"
    
    case isRealTime = "IS_REAL_TIME"
    case canceled   = "CANCELLED"
  }

  public struct RGBColor: Codable {
    let red: Int
    let green: Int
    let blue: Int
    
    var color: SGKColor {
      return SGKColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: 1)
    }
  }
  
  public struct Vehicle: Codable {
    
    /// Representation of real-time occupancy information for public transport
    public enum Occupancy: String, Codable {
      case unknown = "UNKNOWN"
      case empty = "EMPTY"
      case manySeatsAvailable = "MANY_SEATS_AVAILABLE"
      case fewSeatsAvailable = "FEW_SEATS_AVAILABLE"
      case standingRoomOnly = "STANDING_ROOM_ONLY"
      case crushedStandingRoomOnly = "CRUSHED_STANDING_ROOM_ONLY"
      case full = "FULL"
      case notAcceptingPassengers = "NOT_ACCEPTING_PASSENGERS"
    }
    
    let location: Location
    
    let id: String?
    let label: String?
    let icon: URL?
    let lastUpdated: TimeInterval?
    let occupancy: Occupancy?
    let wifi: Bool?
  }
  
}

// MARK: - Convenience helpers

extension API.Vehicle.Occupancy {
  
  public var color: SGKColor? {
    
    switch self {
    case .unknown:
      return nil
    case .empty, .manySeatsAvailable:
      return SGKColor(red: 23/255.0, green: 177/255.0, blue: 94/255.0, alpha: 1)
    case .fewSeatsAvailable:
      return SGKColor(red: 255/255.0, green: 181/255.0, blue: 0/255.0, alpha: 1)
    case .standingRoomOnly, .crushedStandingRoomOnly:
      return SGKColor(red: 255/255.0, green: 150/255.0, blue: 0/255.0, alpha: 1)
    case .full, .notAcceptingPassengers:
      return SGKColor(red: 255/255.0, green: 75/255.0, blue: 71/255.0, alpha: 1)
    }
    
  }
  
  public var description: String? {
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
  
  public init(intValue: Int) {
    switch intValue {
    case 1: self = .empty
    default: self = .unknown
    }
  }
  
  var intValue: Int {
    get {
      switch self {
      case .empty: return 1
      default: return 0
      }
    }
  }

  
}
