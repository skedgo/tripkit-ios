//
//  TKSettings.swift
//  TripKit
//
//  Created by Adrian Schoenig on 4/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension TKSettings {
  
  private enum DefaultsKey: String {
    case sortIndex = "internalSortIndex"
    case ignoreCostToReturnCarHireVehicle = "profileTransportIgnoreCostToReturnCarHireVehicle"
  }
  
  @objc public static var sortOrder: STKTripCostType {
    get {
      let index = UserDefaults.shared.integer(forKey: DefaultsKey.sortIndex.rawValue)
      return STKTripCostType(rawValue: index) ?? .score
    }
    set {
      UserDefaults.shared.set(newValue.rawValue, forKey: DefaultsKey.sortIndex.rawValue)
    }
  }
  
  /// Determine whether two-way-hire vehicles, such as pod-based car-share, should ignore the cost of returning the car-hire vehicle to its pick-up location. By default this is set to `false` and the cost of returning the vehicle to its pick-up location will be added to all one-way trips. Set this to `true` if the cost of the trip should only include the cost that's attributed to this trip and ignore the unavoidable additional cost for returning the vehicle to its pick-up location.
  @objc public static var ignoreCostToReturnCarHireVehicle: Bool {
    get {
      return UserDefaults.shared.bool(forKey: DefaultsKey.ignoreCostToReturnCarHireVehicle.rawValue)
    }
    set {
      UserDefaults.shared.set(newValue, forKey: DefaultsKey.ignoreCostToReturnCarHireVehicle.rawValue)
    }
  }
  
}
