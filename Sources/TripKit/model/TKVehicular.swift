//
//  TKVehicular.swift
//  TripKit
//
//  Created by Adrian Schönig on 17/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public enum TKVehicleType: Int {
  
  case unknown = 0
  case bicycle = 1
  case car = 2
  case motorbike = 3
  case SUV = 4
  case kickscooter = 5
  
}

public protocol TKVehicular {
  
  /// Optional name to use in the UI to refer to this vehicle.
  var name: String? { get }
   
  /// What kind of vehicle it is. Required field.
  var vehicleType: TKVehicleType { get }
  
  /// Where this vehicle is garaged. Can be `nil` but the algorithms won't try to
  /// take it back to the garage then.
  /// - note: `nil` is the same as getting a lift with someone
  var garage: MKAnnotation? { get }
  
  /// The unique identifier that identifies this vehicle.
  /// - note: Getting a lift instances don't have a UUID
  var vehicleID: UUID? { get }
}


extension TKVehicular {
  
  public var isCarPooling: Bool {
    garage == nil
  }
  
  public var icon: TKImage? {
    guard !isCarPooling else {
      return .iconModeCarPool
    }
    
    switch vehicleType {
    case .bicycle:      return .iconModeBicycle
    case .car,
         .SUV:          return .iconModeCar
    case .motorbike:    return .iconModeMotorbike
    case .kickscooter:  return .iconModeKickscooter
    case .unknown:      return nil
    }
  }
  
  public var title: String {
    if isCarPooling {
      return NSLocalizedString("Getting a lift", tableName: "Shared", bundle: .tripKit, comment: "Name for a segment or vehicle where you get a lift from someone.")
    }
    
    if let name = name, !name.isEmpty {
      return name
    } else {
      return vehicleType.title
    }
  }
  
}

extension TKVehicleType {
  public var title: String {
    switch self {
    case .bicycle: return Loc.VehicleTypeBicycle
    case .car: return Loc.VehicleTypeCar
    case .SUV: return Loc.VehicleTypeSUV
    case .motorbike: return Loc.VehicleTypeMotorbike
    case .kickscooter: return Loc.VehicleTypeKickScooter
    case .unknown: return Loc.Unknown
    }
  }
}
