//
//  TKHelperTypes.swift
//  TripKit
//
//  Created by Adrian Schoenig on 28/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import Marshal

public struct TKBikePodInfo : Unmarshaling {
  public let identifier: String
  public let operatorInfo: TKCompanyInfo
  public let inService: Bool
  public let availableBikes: Int?
  public let totalSpaces: Int?
  public let lastUpdate: Date?
  public let source: TKDataAttribution?
  
  public init(object: MarshaledObject) throws {
    identifier      = try  object.value(for: "identifier")
    operatorInfo    = try  object.value(for: "operator")
    inService       = try  object.value(for: "inService")
    availableBikes  = try? object.value(for: "availableBikes")
    totalSpaces     = try? object.value(for: "totalSpaces")
    lastUpdate      = try? object.value(for: "lastUpdate")
    source          = try? object.value(for: "source")
  }
  
  public var availableSpaces: Int? {
    guard let total = totalSpaces, let bikes = availableBikes else { return nil }
    return total - bikes
  }
  
  public var hasRealTime: Bool {
    return inService && availableBikes != nil
  }
}


public struct TKCarPodInfo : Unmarshaling {
  
  public struct Vehicle : Unmarshaling {
    public let name: String?
    public let description: String?
    public let licensePlate: String?
    public let engineType: String?
    public let fuelType: String?
    public let fuel: Int?

    public init(object: MarshaledObject) throws {
      name          = try? object.value(for: "name")
      description   = try? object.value(for: "description")
      licensePlate  = try? object.value(for: "licensePlate")
      engineType    = try? object.value(for: "engine")
      fuelType      = try? object.value(for: "fuelType")
      fuel          = try? object.value(for: "fuel")
    }
  }
  
  
  public let identifier: String
  public let operatorInfo: TKCompanyInfo
  public let vehicles: [Vehicle]
  
  public init(object: MarshaledObject) throws {
    identifier      = try  object.value(for: "identifier")
    operatorInfo    = try  object.value(for: "operator")
    vehicles        = try  object.value(for: "vehicles")
  }
  public var hasRealTime: Bool {
    return false // not yet
  }
}


public struct TKCarParkInfo : Unmarshaling {
  public let identifier: String
  public let name: String
  public let operatorInfo: TKCompanyInfo?
  public let openingHours: TKOpeningHours?
  public let source: TKDataAttribution?
  public let availableSpaces: Int?
  public let totalSpaces: Int?
  public let lastUpdate: Date?
  
  // TODO: Add pricing table
  
  public init(object: MarshaledObject) throws {
    identifier      = try  object.value(for: "identifier")
    name            = try  object.value(for: "name")
    operatorInfo    = try? object.value(for: "operator")
    openingHours    = try? object.value(for: "openingHours")
    source          = try? object.value(for: "source")
    availableSpaces = try? object.value(for: "availableSpaces")
    totalSpaces     = try? object.value(for: "totalSpaces")
    lastUpdate      = try? object.value(for: "lastUpdate")
  }
  
  public var hasRealTime: Bool {
    return availableSpaces != nil
  }
}


public struct TKCarRentalInfo : Unmarshaling {
  public let identifier: String
  public let company: TKCompanyInfo
  public let openingHours: TKOpeningHours?
  public let source: TKDataAttribution?
  
  public init(object: MarshaledObject) throws {
    identifier      = try  object.value(for: "identifier")
    company         = try  object.value(for: "company")
    source          = try? object.value(for: "source")
    openingHours    = try? object.value(for: "openingHours")
  }
}


public class TKLocationInfo : NSObject, Unmarshaling {
  public let what3word: String?
  public let what3wordInfoURL: URL?
  public let transitStop: STKStopAnnotation?
  public let bikePodInfo: TKBikePodInfo?
  public let carPodInfo:  TKCarPodInfo?
  public let carParkInfo: TKCarParkInfo?
  public let carRentalInfo: TKCarRentalInfo?
  
  public required init(object: MarshaledObject) throws {
    what3word = try? object.value(for: "details.w3w")
    what3wordInfoURL = try? object.value(for: "details.w3wInfoURL")
    
    let stop: STKStopCoordinate? = try? object.value(for: "stop")
    transitStop = stop
    
    bikePodInfo   = try? object.value(for: "bikePod")
    carPodInfo    = try? object.value(for: "carPod")
    carParkInfo   = try? object.value(for: "carPark")
    carRentalInfo = try? object.value(for: "carRental")
  }
  
  public var hasRealTime: Bool {
    return carParkInfo?.hasRealTime
        ?? bikePodInfo?.hasRealTime
        ?? carPodInfo?.hasRealTime
        ?? false
  }
}




