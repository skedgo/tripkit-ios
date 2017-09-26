//
//  TKHelperTypes.swift
//  TripKit
//
//  Created by Adrian Schoenig on 28/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

extension API {
  
  public struct BikePodInfo : Codable {
    public let identifier: String
    public let operatorInfo: API.CompanyInfo
    public let inService: Bool
    public let availableBikes: Int?
    public let totalSpaces: Int?
    public let lastUpdate: TimeInterval?
    public let source: API.DataAttribution?
    
    private enum CodingKeys: String, CodingKey {
      case identifier
      case operatorInfo = "operator"
      case inService
      case availableBikes
      case totalSpaces
      case lastUpdate
      case source
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
  
  
  public struct CarPodInfo : Codable {
    
    public struct Vehicle : Codable {
      public let name: String?
      public let description: String?
      public let licensePlate: String?
      public let engineType: String?
      public let fuelType: String?
      public let fuelLevel: Int?
    }
    
    public let identifier: String
    public let operatorInfo: API.CompanyInfo
    public let vehicles: [API.CarPodInfo.Vehicle]
    
    private enum CodingKeys: String, CodingKey {
      case identifier
      case operatorInfo = "operator"
      case vehicles
    }
    
    public var hasRealTime: Bool {
      return false // not yet
    }
  }
  
  
  public struct CarParkInfo : Codable {
    public let identifier: String
    public let name: String
    public let operatorInfo: API.CompanyInfo?
    public let openingHours: API.OpeningHours?
    public let pricingTables: [API.PricingTable]?
    public let availableSpaces: Int?
    public let totalSpaces: Int?
    public let lastUpdate: TimeInterval?
    public let source: API.DataAttribution?

    private enum CodingKeys: String, CodingKey {
      case identifier
      case name
      case operatorInfo = "operator"
      case openingHours
      case pricingTables
      case availableSpaces
      case totalSpaces
      case lastUpdate
      case source
    }
    
    public var hasRealTime: Bool {
      return availableSpaces != nil
    }
  }
  
  
  public struct CarRentalInfo : Codable {
    public let identifier: String
    public let company: API.CompanyInfo
    public let openingHours: API.OpeningHours?
    public let source: API.DataAttribution?
  }

  public struct LocationInfo : Codable {
    public struct Details: Codable {
      public let w3w: String?
      public let w3wInfoURL: URL?
    }
    
    public let details: Details?
    public let stop: STKStopCoordinate?
    public let bikePod: API.BikePodInfo?
    public let carPod:  API.CarPodInfo?
    public let carPark: API.CarParkInfo?
    public let carRental: API.CarRentalInfo?
    
    public var hasRealTime: Bool {
      return carPark?.hasRealTime
        ?? bikePod?.hasRealTime
        ?? carPod?.hasRealTime
        ?? false
    }
  }
}






