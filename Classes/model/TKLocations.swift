//
//  TKLocations.swift
//  Pods
//
//  Created by Adrian Schoenig on 5/12/16.
//
//

import Foundation

import Marshal
import SGCoreKit


public protocol TKRealTimeLocation {
  
  var hasRealTime: Bool { get }
  
}


public class TKBikePodLocation: STKModeCoordinate, TKRealTimeLocation {
  
  public let bikePod: TKBikePodInfo
  
  public required init(object: MarshaledObject) throws {
    bikePod = try object.value(for: "bikePod")
    try super.init(object: object)
  }
  
  public required init?(coder aDecoder: NSCoder) {
    guard let info = aDecoder.decodeObject(forKey: "bikePod") as? TKBikePodInfo else { return nil }
    bikePod = info
    super.init(coder: aDecoder)
  }
  
  public var hasRealTime: Bool { return bikePod.hasRealTime }
}


public class TKCarPodLocation: STKModeCoordinate, TKRealTimeLocation {
  
  public let carPod: TKCarPodInfo
  
  public required init(object: MarshaledObject) throws {
    carPod = try object.value(for: "carPod")
    try super.init(object: object)
  }
  
  public required init?(coder aDecoder: NSCoder) {
    guard let info = aDecoder.decodeObject(forKey: "carPod") as? TKCarPodInfo else { return nil }
    carPod = info
    super.init(coder: aDecoder)
  }
  
  public var hasRealTime: Bool { return carPod.hasRealTime }
}


public class TKCarParkLocation: STKModeCoordinate, TKRealTimeLocation {
  
  public let carPark: TKCarParkInfo
  
  public required init(object: MarshaledObject) throws {
    carPark = try object.value(for: "carPark")
    try super.init(object: object)
  }

  public required init?(coder aDecoder: NSCoder) {
    guard let info = aDecoder.decodeObject(forKey: "carPark") as? TKCarParkInfo else { return nil }
    carPark = info
    super.init(coder: aDecoder)
  }

  public var hasRealTime: Bool { return carPark.hasRealTime }
}
