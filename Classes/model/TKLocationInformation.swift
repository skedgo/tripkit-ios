//
//  TKHelperTypes.swift
//  TripKit
//
//  Created by Adrian Schoenig on 28/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import Marshal

public struct TKBikePodInfo : Unmarshaling, Marshaling {
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
  
  public typealias MarshalType = [String: Any]
  
  public func marshaled() -> MarshalType {
    var marshaled : MarshalType =  [
      "identifier": identifier,
      "operator": operatorInfo.marshaled(),
      "inService": inService,
    ]
    
    marshaled["availableBikes"] = availableBikes
    marshaled["totalSpaces"] = totalSpaces
    marshaled["lastUpdate"] = lastUpdate
    marshaled["source"] = source?.marshaled()
    return marshaled
  }
  
  
  public var availableSpaces: Int? {
    guard let total = totalSpaces, let bikes = availableBikes else { return nil }
    return total - bikes
  }
  
  public var hasRealTime: Bool {
    return inService && availableBikes != nil
  }
}


public struct TKCarPodInfo : Unmarshaling, Marshaling {
  
  public struct Vehicle : Unmarshaling, Marshaling {
    public let name: String?
    public let description: String?
    public let licensePlate: String?
    public let engineType: String?
    public let fuelType: String?
    public let fuelLevel: Int?

    public init(object: MarshaledObject) throws {
      name          = try? object.value(for: "name")
      description   = try? object.value(for: "description")
      licensePlate  = try? object.value(for: "licensePlate")
      engineType    = try? object.value(for: "engineType")
      fuelType      = try? object.value(for: "fuelType")
      fuelLevel     = try? object.value(for: "fuelLevel")
    }
    
    public typealias MarshalType = [String: Any]
    
    public func marshaled() -> MarshalType {
      var marshaled = MarshalType()
      marshaled["name"] = name
      marshaled["description"] = description
      marshaled["licensePlate"] = licensePlate
      marshaled["engineType"] = engineType
      marshaled["fuelType"] = fuelType
      marshaled["fuelLevel"] = fuelLevel
      return marshaled
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
  
  
  public typealias MarshalType = [String: Any]
  
  public func marshaled() -> MarshalType {
    return [
      "identifier": identifier,
      "operatorInfo": operatorInfo.marshaled(),
      "vehicles": vehicles.map { $0.marshaled() }
    ]
  }

  
  public var hasRealTime: Bool {
    return false // not yet
  }
}


public struct TKCarParkInfo : Unmarshaling, Marshaling {
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
  
  
  public typealias MarshalType = [String: Any]
  
  public func marshaled() -> MarshalType {
    var marshaled : MarshalType =  [
      "identifier": identifier,
      "name": name,
      ]
    
    marshaled["operator"] = operatorInfo?.marshaled()
    marshaled["openingHours"] = openingHours?.marshaled()
    marshaled["source"] = source?.marshaled()
    marshaled["availableSpaces"] = availableSpaces
    marshaled["totalSpaces"] = totalSpaces
    marshaled["lastUpdate"] = lastUpdate
    return marshaled
  }
  
  
  public var hasRealTime: Bool {
    return availableSpaces != nil
  }
}


public struct TKCarRentalInfo : Unmarshaling, Marshaling {
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
  
  
  public typealias MarshalType = [String: Any]
  
  public func marshaled() -> MarshalType {
    var marshaled : MarshalType =  [
      "identifier": identifier,
      "company": company.marshaled(),
    ]
    
    marshaled["source"] = source?.marshaled()
    marshaled["openingHours"] = openingHours?.marshaled()
    return marshaled
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




