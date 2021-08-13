//
//  TKSettings.swift
//  TripKit
//
//  Created by Adrian Schoenig on 4/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

#if SWIFT_PACKAGE
import TripKitObjc
#endif

extension TKSettings {
  
  private enum DefaultsKey: String {
    case sortIndex = "internalSortIndex"
    case includeCostToReturnCarHireVehicle = "profileTransportIncludeCostToReturnCarHireVehicle"
  }
  
  @objc public static var sortOrder: TKTripCostType {
    get {
      let index = UserDefaults.shared.integer(forKey: DefaultsKey.sortIndex.rawValue)
      return TKTripCostType(rawValue: index) ?? .score
    }
    set {
      UserDefaults.shared.set(newValue.rawValue, forKey: DefaultsKey.sortIndex.rawValue)
    }
  }
  
  /// Determine whether two-way-hire vehicles, such as pod-based car-share, should include the cost of returning the car-hire vehicle to its pick-up location. By default this is set to `false` and the cost of the trip only include the cost that's attributed to this trip and ignore the unavoidable additional cost for returning the vehicle to its pick-up location. Set this to `true` if the cost of returning the vehicle to its pick-up location should be added to all one-way trips.
  @objc public static var includeCostToReturnCarHireVehicle: Bool {
    get {
      return UserDefaults.shared.bool(forKey: DefaultsKey.includeCostToReturnCarHireVehicle.rawValue)
    }
    set {
      UserDefaults.shared.set(newValue, forKey: DefaultsKey.includeCostToReturnCarHireVehicle.rawValue)
    }
  }
  
}
