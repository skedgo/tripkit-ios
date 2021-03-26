//
//  TKHelperTypes.swift
//  TripKit
//
//  Created by Adrian Schoenig on 28/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation
import CoreLocation

protocol RealTimeUpdatable {
  var hasRealTime: Bool { get }
}

extension TKAPI {
  
  public enum SharedVehicleType: String, Codable {
    case bike = "BIKE"
    case pedelec = "PEDELEC"
    case kickScooter = "KICK_SCOOTER"
    case motoScooter = "MOTO_SCOOTER"
    case car = "CAR"
  }
  
  public struct BikePodInfo: Codable, Hashable, RealTimeUpdatable {
    // static information
    public let identifier: String
    public let operatorInfo: TKAPI.CompanyInfo
    public let source: TKAPI.DataAttribution?
    public let deepLink: URL?

    // availability information (usually real-time)
    public let inService: Bool
    public let availableBikes: Int?
    public let totalSpaces: Int?
    public let lastUpdate: TimeInterval?
    
    
    private enum CodingKeys: String, CodingKey {
      case identifier
      case operatorInfo = "operator"
      case source
      case deepLink
      case inService
      case availableBikes
      case totalSpaces
      case lastUpdate
    }
    
    public var availableSpaces: Int? {
      guard let total = totalSpaces, let bikes = availableBikes else { return nil }
      
      // available bikes can exceed number of spaces!
      return max(0, total - bikes)
    }
    
    public var hasRealTime: Bool {
      return inService && availableBikes != nil
    }
  }
  
  
  public struct CarPodInfo: Codable, Hashable, RealTimeUpdatable {
    // static information
    public let identifier: String
    public let operatorInfo: TKAPI.CompanyInfo
    public let deepLink: URL?

    // real-time availability information
    public let availabilityMode: TKAPI.AvailabilityMode?
    public let availabilities: [TKAPI.CarAvailability]?
    public let inService: Bool?
    public let availableVehicles: Int?
    public let availableChargingSpaces: Int?
    public let totalSpaces: Int?
    public let lastUpdate: TimeInterval?

    private enum CodingKeys: String, CodingKey {
      case identifier
      case operatorInfo = "operator"
      case deepLink

      case availabilityMode
      case availabilities
      case inService
      case availableVehicles
      case availableChargingSpaces
      case totalSpaces
      case lastUpdate
    }
    
    public var availableSpaces: Int? {
      guard let total = totalSpaces, let vehicles = availableVehicles else { return nil }
      
      // available vehicles can exceed number of spaces!
      return max(0, total - vehicles)
    }

    public var hasRealTime: Bool {
      return inService != false && availableVehicles != nil
    }
  }
  
  
  public struct CarParkInfo: Codable, Hashable, RealTimeUpdatable {
    
    public enum EntranceType: String, Codable {
      case entranceAndExit = "ENTRANCE_EXIT"
      case entranceOnly = "ENTRANCE_ONLY"
      case exitOnly = "EXIT_ONLY"
      case pedestrian = "PEDESTRIAN"
      case disabledPedestrian = "DISABLED_PEDESTRIAN"
      case permit = "PERMIT"
    }
    
    public struct Entrance: Codable, Hashable {
      public let type: EntranceType
      public let lat: CLLocationDegrees
      public let lng: CLLocationDegrees
      public let address: String?
    }
    
    public let identifier: String
    public let name: String

    public let operatorInfo: TKAPI.CompanyInfo?
    public let source: TKAPI.DataAttribution?
    public let deepLink: URL?

    /// Additional information text from the provider. Can be long and over multiple lines.
    public let info: String?
    
    /// The polygon defining the parking area as an encoded polyline.
    ///
    /// See `CLLocationCoordinate2D.decodePolyline`
    public let encodedParkingArea: String?
    
    public let entrances: [Entrance]?
    public let openingHours: TKAPI.OpeningHours?
    public let pricingTables: [TKAPI.PricingTable]?
    public let availableSpaces: Int?
    public let totalSpaces: Int?
    public let lastUpdate: TimeInterval?

    private enum CodingKeys: String, CodingKey {
      case identifier
      case name
      case operatorInfo = "operator"
      case source
      case deepLink
      case encodedParkingArea
      case info
      case entrances
      case openingHours
      case pricingTables
      case availableSpaces
      case totalSpaces
      case lastUpdate
    }
    
    public var hasRealTime: Bool {
      return availableSpaces != nil
    }
  }
  
  public struct CarRentalInfo: Codable, Hashable, RealTimeUpdatable {
    public let identifier: String
    public let company: TKAPI.CompanyInfo
    public let openingHours: TKAPI.OpeningHours?
    public let source: TKAPI.DataAttribution?
    public var hasRealTime: Bool { false }
  }
  

  @available(*, unavailable, renamed: "SharedVehicleInfo")
  public typealias FreeFloatingVehicleInfo = SharedVehicleInfo

  public struct SharedVehicleInfo: Codable, Hashable, RealTimeUpdatable {
    public let identifier: String
    public let operatorInfo: TKAPI.CompanyInfo
    public let vehicleType: SharedVehicleType
    public let source: TKAPI.DataAttribution?
    public let deepLink: URL?

    public let name: String?
    public let isAvailable: Bool?
    public let batteryLevel: Int? // percentage, i.e., 0-100
    public let batteryRange: Int? // kilometres
    public let lastUpdate: TimeInterval?
    
    private enum CodingKeys: String, CodingKey {
      case identifier
      case operatorInfo = "operator"
      case vehicleType
      case source
      case name
      case isAvailable = "available"
      case batteryLevel
      case batteryRange
      case lastUpdate
      case deepLink = "deepLinks"
    }
    
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      identifier = try container.decode(String.self, forKey: .identifier)
      operatorInfo = try container.decode(TKAPI.CompanyInfo.self, forKey: .operatorInfo)
      vehicleType = try container.decode(SharedVehicleType.self, forKey: .vehicleType)
      source = try? container.decode(TKAPI.DataAttribution.self, forKey: .source)
      
      if let deepLinkDict = try? container.decode([String: String].self, forKey: .deepLink),
         let link = deepLinkDict["ios"],
         let linkURL = URL(string: link) {
        deepLink = linkURL
      } else {
        deepLink = nil
      }
      
      name = try? container.decode(String.self, forKey: .name)
      isAvailable = try? container.decode(Bool.self, forKey: .isAvailable)
      batteryLevel = try? container.decode(Int.self, forKey: .batteryLevel)
      batteryRange = try? container.decode(Int.self, forKey: .batteryRange)
      lastUpdate = try? container.decode(TimeInterval.self, forKey: .lastUpdate)
    }
    
    public var hasRealTime: Bool { true }
  }
  
  public struct OnStreetParkingInfo: Codable, Hashable, RealTimeUpdatable {
    public enum PaymentType: String, Codable {
      case meter = "METER"
      case creditCard = "CREDIT_CARD"
      case phone = "PHONE"
      case coins = "COINS"
      case app = "APP"
    }
    
    public enum AvailableContent: String, Codable, CaseIterable {
      public init(from decoder: Decoder) throws {
        // We do this manually rather than using the default Codable
        // implementation, to flag unknown content as `.unknown`.
        let single = try decoder.singleValueContainer()
        let string = try single.decode(String.self)
        let match = AvailableContent.allCases.first { $0.rawValue == string }
        if let known = match {
          self = known
        } else {
          self = .unknown
        }
      }
      
      public func encode(to encoder: Encoder) throws {
        var single = encoder.singleValueContainer()
        try single.encode(rawValue)
      }
      
      case restrictions
      case paymentTypes
      case totalSpaces
      case availableSpaces
      case actualRate
      case unknown
    }
    
    public enum Vacancy: String, Codable {
      case unknown = "UNKNOWN"
      case full = "NO_VACANCY"
      case limited = "LIMITED_VACANCY"
      case plenty = "PLENTY_VACANCY"
    }
    
    public struct Restriction: Codable, Hashable {
      public let color: String
      public let maximumParkingMinutes: Int
      public let parkingSymbol: String
      public let daysAndTimes: OpeningHours
      public let type: String
    }
    
    public let actualRate: String?
    public let identifier: String
    public let description: String
    public let availableContent: [AvailableContent]?
    public let source: TKAPI.DataAttribution?

    public let paymentTypes: [PaymentType]?
    public let restrictions: [Restriction]?
    
    public let availableSpaces: Int?
    public let totalSpaces: Int?
    public let occupiedSpaces: Int?
    public let parkingVacancy: Vacancy?
    public let lastUpdate: TimeInterval?

    /// The polyline defining the parking area along the street as an encoded polyline.
    ///
    /// This is optional as some on-street parking isn't defined by a line,
    /// but by an area. See `encodedPolygon`
    ///
    /// See `CLLocationCoordinate2D.decodePolyline`
    public let encodedPolyline: String?

    /// The polygon defining the parking area as an encoded polyline.
    ///
    /// This is optional as most on-street parking isn't defined by an area,
    /// but by a line. See `encodedPolyline`
    ///
    /// See `CLLocationCoordinate2D.decodePolyline`
    public let encodedPolygon: String?
    
    public var hasRealTime: Bool {
      return availableSpaces != nil
    }
  }
  
  public struct LocationInfo : Codable, Hashable, RealTimeUpdatable {
    public struct Details: Codable, Hashable {
      public let w3w: String?
      public let w3wInfoURL: URL?
    }
    
    public let details: Details?
    public let alerts: [Alert]?
    
    public let stop: TKStopCoordinate?
    public let bikePod: TKAPI.BikePodInfo?
    public let carPod:  TKAPI.CarPodInfo?
    public let carPark: TKAPI.CarParkInfo?
    public let carRental: TKAPI.CarRentalInfo?
    public let freeFloating: TKAPI.SharedVehicleInfo? // TODO: Also add to API specs
    public let onStreetParking: TKAPI.OnStreetParkingInfo?

    
    public var hasRealTime: Bool {
      let sources: [RealTimeUpdatable?] = [bikePod, carPod, carPod, carRental, freeFloating, onStreetParking]
      return sources.contains { $0?.hasRealTime == true }
    }
  }
  
  public struct LocationsResponse: Codable, Hashable {
    public static let empty: LocationsResponse = LocationsResponse(groups: [])
    
    public let groups: [Group]
    
    public struct Group: Codable, Hashable {
      public let key: String
      public let hashCode: Int
      public let stops: [TKStopCoordinate]?
      public let bikePods: [TKBikePodLocation]?
      public let carPods: [TKCarPodLocation]?
      public let carParks: [TKCarParkLocation]?
      public let carRentals: [TKCarRentalLocation]?
      public let freeFloating: [TKFreeFloatingVehicleLocation]?
      public let onStreetParking: [TKOnStreetParkingLocation]?

      public var all: [TKModeCoordinate] {
        return (stops ?? [])        as [TKModeCoordinate]
          + (bikePods ?? [])        as [TKModeCoordinate]
          + (carPods ?? [])         as [TKModeCoordinate]
          + (carParks ?? [])        as [TKModeCoordinate]
          + (carRentals ?? [])      as [TKModeCoordinate]
          + (freeFloating ?? [])    as [TKModeCoordinate]
          + (onStreetParking ?? []) as [TKModeCoordinate]
      }
        
    }
  }
}
