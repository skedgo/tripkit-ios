//
//  TKHelperTypes.swift
//  TripKit
//
//  Created by Adrian Schoenig on 28/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation
import CoreLocation

extension API {
  
  public enum SharedVehicleType: String, Codable, Equatable {
    case bike = "BIKE"
    case pedelec = "PEDELEC"
    case kickScooter = "KICK_SCOOTER"
    case motoScooter = "MOTO_SCOOTER"
    case car = "CAR"
  }
  
  public struct BikePodInfo: Codable, Equatable {
    // static information
    public let identifier: String
    public let operatorInfo: API.CompanyInfo
    public let source: API.DataAttribution?
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
  
  
  public struct CarPodInfo: Codable, Equatable {
    // static information
    public let identifier: String
    public let operatorInfo: API.CompanyInfo
    public let deepLink: URL?

    // real-time availability information
    public let availabilityMode: API.AvailabilityMode?
    public let availabilities: [API.CarAvailability]?
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
  
  
  public struct CarParkInfo: Codable, Equatable {
    
    public enum EntranceType: String, Codable {
      case entranceAndExit = "ENTRANCE_EXIT"
      case entranceOnly = "ENTRANCE_ONLY"
      case exitOnly = "EXIT_ONLY"
      case pedestrian = "PEDESTRIAN"
      case disabledPedestrian = "DISABLED_PEDESTRIAN"
      case permit = "PERMIT"
    }
    
    public struct Entrance: Codable, Equatable {
      public let type: EntranceType
      public let lat: CLLocationDegrees
      public let lng: CLLocationDegrees
      public let address: String?
    }
    
    public let identifier: String
    public let name: String

    public let operatorInfo: API.CompanyInfo?
    public let source: API.DataAttribution?
    public let deepLink: URL?

    /// Additional information text from the provider. Can be long and over multiple lines.
    public let info: String?
    
    /// The polygon defining the parking area as an encoded polyline.
    ///
    /// See `CLLocation.decodePolyLine`
    public let encodedParkingArea: String?
    
    public let entrances: [Entrance]?
    public let openingHours: API.OpeningHours?
    public let pricingTables: [API.PricingTable]?
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
  
  
  public struct CarRentalInfo: Codable, Equatable {
    public let identifier: String
    public let company: API.CompanyInfo
    public let openingHours: API.OpeningHours?
    public let source: API.DataAttribution?
  }

  public struct FreeFloatingVehicleInfo: Codable, Equatable {
    public let identifier: String
    public let operatorInfo: API.CompanyInfo
    public let vehicleType: SharedVehicleType
    public let source: API.DataAttribution?

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
      case isAvailable
      case batteryLevel
      case batteryRange
      case lastUpdate
    }
    
    public var hasRealTime: Bool {
      return true
    }
  }
  
  public struct OnStreetParkingInfo: Codable, Equatable {
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
      case unknown
    }
    
    public struct Restriction: Codable, Equatable {
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
    public let source: API.DataAttribution?

    public let paymentTypes: [PaymentType]?
    public let restrictions: [Restriction]?
    
    public let availableSpaces: Int?
    public let totalSpaces: Int?
    public let lastUpdate: TimeInterval?

    /// The polyline defining the parking area along the street as an encoded polyline.
    ///
    /// This is optional as some on-street parking isn't defined by a line,
    /// but by an area. See `encodedPolygon`
    ///
    /// See `CLLocation.decodePolyLine`
    public let encodedPolyline: String?

    /// The polygon defining the parking area as an encoded polyline.
    ///
    /// This is optional as most on-street parking isn't defined by an area,
    /// but by a line. See `encodedPolyline`
    ///
    /// See `CLLocation.decodePolyLine`
    public let encodedPolygon: String?
    
    public var hasRealTime: Bool {
      return availableSpaces != nil
    }
  }
  
  public struct LocationInfo : Codable, Equatable {
    public struct Details: Codable, Equatable {
      public let w3w: String?
      public let w3wInfoURL: URL?
    }
    
    public let details: Details?
    public let stop: TKStopCoordinate?
    public let bikePod: API.BikePodInfo?
    public let carPod:  API.CarPodInfo?
    public let carPark: API.CarParkInfo?
    public let carRental: API.CarRentalInfo?
    public let freeFloating: API.FreeFloatingVehicleInfo?
    public let onStreetParking: API.OnStreetParkingInfo?

    
    public var hasRealTime: Bool {
      return carPark?.hasRealTime
        ?? bikePod?.hasRealTime
        ?? carPod?.hasRealTime
        ?? freeFloating?.hasRealTime
        ?? onStreetParking?.hasRealTime
        ?? false
    }
  }
  
  public struct LocationsResponse: Codable, Equatable {
    public static let empty: LocationsResponse = LocationsResponse(groups: [])
    
    public let groups: [Group]
    
    public struct Group: Codable, Equatable {
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
