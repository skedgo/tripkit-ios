//
//  TKHelperTypes.swift
//  TripKit
//
//  Created by Adrian Schoenig on 28/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import Marshal

public struct BikePodInfo : Unmarshaling {
  public let identifier: String
  public let operatorInfo: CompanyInfo
  public let availableBikes: Int?
  public let totalSpaces: Int?
  public let lastUpdate: Date?
  public let source: DataAttribution?
  
  public init(object: MarshaledObject) throws {
    identifier      = try  object.value(for: "identifier")
    operatorInfo    = try  object.value(for: "operator")
    availableBikes  = try? object.value(for: "availableBikes")
    totalSpaces     = try? object.value(for: "totalSpaces")
    lastUpdate      = try? object.value(for: "lastUpdate")
    source          = try? object.value(for: "source")
  }
  
  public var availableSpaces: Int? {
    guard let total = totalSpaces, let bikes = availableBikes else { return -1 }
    return total - bikes
  }
}

public struct CarParkInfo : Unmarshaling {
  public let identifier: String
  public let name: String
  public let availableSpaces: Int?
  public let totalSpaces: Int?
  public let lastUpdate: Date?
  
  public init(object: MarshaledObject) throws {
    identifier      = try  object.value(for: "identifier")
    name            = try  object.value(for: "name")
    availableSpaces = try? object.value(for: "availableSpaces")
    totalSpaces     = try? object.value(for: "totalSpaces")
    lastUpdate      = try? object.value(for: "lastUpdate")
  }
}

public class LocationInformation : NSObject, Unmarshaling {
  public let what3word: String?
  public let what3wordInfoURL: URL?
  public let transitStop: STKStopAnnotation?
  public let bikePodInfo: BikePodInfo?
  public let carParkInfo: CarParkInfo?
  
  public required init(object: MarshaledObject) throws {
    what3word = try? object.value(for: "details.w3w")
    what3wordInfoURL = try? object.value(for: "details.w3wInfoURL")
    
    let stop: STKStopCoordinate? = try? object.value(for: "stop")
    transitStop = stop
    
    bikePodInfo = try? object.value(for: "bikePod")
    carParkInfo = try? object.value(for: "carPark")
  }
  
  public var hasRealTime: Bool {
    if let carParkInfo = carParkInfo {
      return carParkInfo.availableSpaces != nil
    } else {
      return false
    }
  }
}

