//
//  Trip.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension Trip {
  
  public var primaryCostType: STKTripCostType {
    if departureTimeIsFixed {
      return .time
    } else if isExpensive {
      return .price
    } else {
      return .duration
    }
  }
  
  private var isExpensive: Bool {
    guard let identifier = mainSegment().modeIdentifier() else { return false }
    return SVKTransportModes.modeIdentifierIsExpensive(identifier)
  }
  
}

// MARK: - Vehicles

extension Trip {
  
  /// If the trip uses a personal vehicle (non shared) which the user might want to assign to one of their vehicles
  public var usedPrivateVehicleType: STKVehicleType {
    for segment in segments() {
      let vehicleType = segment.privateVehicleType
      if vehicleType != .none {
        return vehicleType
      }
    }
    return .none
  }
  
  /// Segments of this trip which do use a private (or shared) vehicle, i.e., those who return something from `usedVehicle`.
  public var vehicleSegments: Set<TKSegment> {
    return segments().reduce(mutating: Set()) { acc, segment in
      if !segment.isStationary() && segment.usesVehicle {
        acc.insert(segment)
      }
    }
  }
  
  /// - Parameter vehicle: The vehicle to assign this trip to. `nil` to reset to a generic vehicle.
  public func assignVehicle(_ vehicle: STKVehicular?) {
    segments().forEach { $0.assignVehicle(vehicle) }
  }
  
}
