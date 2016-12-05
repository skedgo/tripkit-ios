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

public class TKBikePodLocation: STKModeCoordinate {
  
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
  
}


public class TKCarParkLocation: STKModeCoordinate {
  
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

}
