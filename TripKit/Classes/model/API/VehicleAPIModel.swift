//
//  VehicleAPIModel.swift
//  TripKit
//
//  Created by Adrian Schönig on 21.11.17.
//

import Foundation

// MARK: - Real-time vehicles

extension API {
  
  public struct Vehicle: Codable, Equatable {
    
    @available(*, unavailable, renamed: "API.VehicleOccupancy")
    public typealias Occupancy = VehicleOccupancy
    
    public let location: Location
    
    public let id: String?
    public let label: String?
    public let icon: URL?
    public let lastUpdate: TimeInterval?
    
    /// Components of this vehicle with additional information.
    ///
    /// The top level array represents connected parts of the vehicle, which you can't walk through
    /// without leaving the vehicle (e.g., two trains connected together). The inner level array
    /// represents then parts that can be walked through (e.g., the waggons of a train). A bus
    /// would have a `[[component1]]`. A train could have `[[c1, c2, c3, c4], [c5, c6, c7, c8]]`.
    ///
    /// The arrays are ordered by direction of travel always being left-to-right, i.e., the front of the train is the very last element.
    public let components: [[VehicleComponents]]?
  }
  
  /// Representation of real-time occupancy information for public transport
  public enum VehicleOccupancy: String, Codable, Equatable {
    case unknown = "UNKNOWN"
    case empty = "EMPTY"
    case manySeatsAvailable = "MANY_SEATS_AVAILABLE"
    case fewSeatsAvailable = "FEW_SEATS_AVAILABLE"
    case standingRoomOnly = "STANDING_ROOM_ONLY"
    case crushedStandingRoomOnly = "CRUSHED_STANDING_ROOM_ONLY"
    case full = "FULL"
    case notAcceptingPassengers = "NOT_ACCEPTING_PASSENGERS"
  }
  
  public struct VehicleComponents: Codable, Equatable {
    public let wifi: Bool?
    public let occupancy: VehicleOccupancy?
  }
  
}

extension API.VehicleOccupancy {
  
  public var color: SGKColor? {
    
    switch self {
    case .unknown: return nil
    case .empty, .manySeatsAvailable: return #colorLiteral(red: 0, green: 0.7333984971, blue: 0.4438126683, alpha: 1)
    case .fewSeatsAvailable: return #colorLiteral(red: 1, green: 0.7553820014, blue: 0, alpha: 1)
    case .standingRoomOnly, .crushedStandingRoomOnly: return #colorLiteral(red: 1, green: 0.6531761289, blue: 0, alpha: 1)
    case .full, .notAcceptingPassengers: return#colorLiteral(red: 1, green: 0.3921365738, blue: 0.34667629, alpha: 1)
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
    case 2: self = .manySeatsAvailable
    case 3: self = .fewSeatsAvailable
    case 4: self = .standingRoomOnly
    case 5: self = .crushedStandingRoomOnly
    case 6: self = .full
    case 7: self = .notAcceptingPassengers
    default: self = .unknown
    }
  }
  
  var intValue: Int {
    get {
      switch self {
      case .unknown: return 0
      case .empty: return 1
      case .manySeatsAvailable: return 2
      case .fewSeatsAvailable: return 3
      case .standingRoomOnly: return 4
      case .crushedStandingRoomOnly: return 5
      case .full: return 6
      case .notAcceptingPassengers: return 7
      }
    }
  }
  
}

// MARK: - Private vehicles

extension API {
  public enum PrivateVehicleType: String, Codable {
    case bicycle
    case motorbike
    case car
    case SUV = "4wd"
  }
  
  /// The TripGo API-compliant dictionary representation of a vehicle
  public struct PrivateVehicle: Codable {
    let type: PrivateVehicleType
    let UUID: String?
    let name: String?
    let garage: Location?
  }
}


