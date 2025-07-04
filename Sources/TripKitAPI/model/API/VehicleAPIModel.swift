//
//  VehicleAPIModel.swift
//  TripKit
//
//  Created by Adrian Schönig on 21.11.17.
//

import Foundation

// MARK: - Real-time vehicles

extension TKAPI {
  
  public struct Vehicle: Codable, Hashable {
    
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
    /// represents then parts that can be walked through (e.g., the carriages of a train). A bus
    /// would have a `[[component1]]`. A train could have `[[c1, c2, c3, c4], [c5, c6, c7, c8]]`.
    ///
    /// The arrays are ordered by direction of travel always being left-to-right,
    /// i.e., the front of the train is the very last element.
    public let components: [[VehicleComponents]]?
  }
  
  /// Representation of real-time occupancy information for public transport
  public enum VehicleOccupancy: String, Codable, Hashable {
    case unknown = "UNKNOWN"
    case empty = "EMPTY"
    case manySeatsAvailable = "MANY_SEATS_AVAILABLE"
    case fewSeatsAvailable = "FEW_SEATS_AVAILABLE"
    case standingRoomOnly = "STANDING_ROOM_ONLY"
    case crushedStandingRoomOnly = "CRUSHED_STANDING_ROOM_ONLY"
    case full = "FULL"
    case notAcceptingPassengers = "NOT_ACCEPTING_PASSENGERS"
  }
  
  /// Components of a vehicle, typically provided as a nested array, see ``TripKitAPI/TKAPI/Vehicle/components``
  public struct VehicleComponents: Codable, Hashable {
    public let airConditioned: Bool?
    public let model: String?
    public let occupancy: VehicleOccupancy?
    public let occupancyText: String?
    public let wheelchairAccessible: Bool?
    public let wheelchairSeats: Int?
    public let wifi: Bool?
  }
  
}

extension TKAPI.VehicleOccupancy {
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
  
  public var intValue: Int {
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

extension TKAPI {
  public enum PrivateVehicleType: String, Codable {
    case bicycle
    case motorbike
    case car
    case SUV = "4wd"
  }
  
  /// The TripGo API-compliant dictionary representation of a vehicle
  public struct PrivateVehicle: Codable, Hashable {
    public let type: PrivateVehicleType
    public let UUID: String?
    public let name: String?
    public let garage: Location?
    
    public init(type: PrivateVehicleType, UUID: String?, name: String?, garage: Location?) {
      self.type = type
      self.UUID = UUID
      self.name = name
      self.garage = garage
    }
  }
}

// MARK: - Shared vehicles

extension TKAPI {
  
  public enum VehicleFormFactor: String, Codable {
    case bicycle = "BICYCLE"
    case car = "CAR"
    case scooter = "SCOOTER"
    case moped = "MOPED"
    case other = "OTHER"
  }

  public enum VehiclePropulsionType: String, Codable {
    case human = "HUMAN"
    case electric = "ELECTRIC"
    case electricAssist = "ELECTRIC_ASSIST"
    case combustion = "COMBUSTION"
  }

  public struct VehicleTypeInfo: Codable, Hashable {
    public let name: String?
    public let formFactor: VehicleFormFactor
    public let propulsionType: VehiclePropulsionType?
    public let maxRangeMeters: Int?
  }
  
  
  public struct SharedVehicleInfo: Codable, Hashable {
    public let identifier: String
    public let name: String?
    public let details: String?

    public let operatorInfo: TKAPI.CompanyInfo
    public let vehicleType: VehicleTypeInfo
    public let source: TKAPI.DataAttribution?
    public let deepLink: URL?
    public let imageURL: URL?

    public let licensePlate: String?
    public let isDisabled: Bool
    public let isReserved: Bool?
    
    public let batteryLevel: Int? // percentage, i.e., 0-100
    public let currentRange: Distance? // metres
    public let lastReported: Date?
    
    private enum CodingKeys: String, CodingKey {
      case identifier
      case name
      case batteryLevel
      case operatorInfo = "operator"
      case licensePlate
      case vehicleType = "vehicleTypeInfo"
      case isDisabled = "disabled"
      case isReserved = "reserved"
      case lastReported
      case currentRange = "currentRangeMeters"

      case imageURL // NOT DOCUMENTED
      case details = "description"
      case source
      case deepLink = "deepLinks" // NOT DOCUMENTED
    }
    
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      identifier = try container.decode(String.self, forKey: .identifier)
      operatorInfo = try container.decode(TKAPI.CompanyInfo.self, forKey: .operatorInfo)
      vehicleType = try container.decode(VehicleTypeInfo.self, forKey: .vehicleType)
      isDisabled = try container.decode(Bool.self, forKey: .isDisabled)

      source = try? container.decode(TKAPI.DataAttribution.self, forKey: .source)
      
      if let deepLinkDict = try? container.decode([String: String].self, forKey: .deepLink),
         let link = deepLinkDict["ios"],
         let linkURL = URL(string: link) {
        deepLink = linkURL
      } else {
        deepLink = nil
      }
      
      name = try? container.decode(String.self, forKey: .name)
      details = try? container.decode(String.self, forKey: .details)
      imageURL = try? container.decode(URL.self, forKey: .imageURL)
      licensePlate = try? container.decode(String.self, forKey: .licensePlate)
      isReserved = try? container.decode(Bool.self, forKey: .isReserved)
      batteryLevel = try? container.decode(Int.self, forKey: .batteryLevel)
      currentRange = try? container.decode(Distance.self, forKey: .currentRange)
      lastReported = try? container.decode(Date.self, forKey: .lastReported)
    }
    
    public var isAvailable: Bool { !isDisabled && (isReserved != true) }
  }
  
}
