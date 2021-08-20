//
//  TKVehicular.swift
//  TripKit
//
//  Created by Adrian Schönig on 17/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

/// :nodoc:
@objc(TKVehicularHelper)
public class _TKVehicularHelper: NSObject {
  
  private override init() {
    super.init()
  }
  
  @objc(iconForVehicle:)
  public static func _icon(for vehicle: TKVehicular) -> TKImage? {
    return vehicle.icon
  }
  
  @objc(titleForVehicle:)
  public static func _title(for vehicle: TKVehicular) -> String? {
    return vehicle.title
  }

  @objc(stringForVehicleType:)
  public static func _title(for vehicleType: TKVehicleType) -> String? {
    return vehicleType.title
  }
}

extension TKVehicular {
  
  public var icon: TKImage? {
    if garage?() != nil {
      return TKStyleManager.image(named: "icon-mode-car-pool")
    }
    
    switch vehicleType() {
    case .bicycle:
      return TKStyleManager.image(named: "icon-mode-bicycle")
      
    case .car, .SUV:
      return TKStyleManager.image(named: "icon-mode-car")

    case .motorbike:
      return TKStyleManager.image(named: "icon-mode-motorbike")
      
    default:
      return nil
    }
  }
  
  public var title: String? {
    if garage?() != nil {
      return NSLocalizedString("Getting a lift", tableName: "Shared", bundle: .tripKit, comment: "Name for a segment or vehicle where you get a lift from someone.")
    }
    
    if let name = name(), !name.isEmpty {
      return name
    } else {
      return vehicleType().title
    }
  }
  
}

extension TKVehicleType {
  public var title: String? {
    switch self {
    case .bicycle: return Loc.VehicleTypeBicycle
    case .car: return Loc.VehicleTypeCar
    case .SUV: return Loc.VehicleTypeSUV
    case .motorbike: return Loc.VehicleTypeMotorbike
    default: return nil
    }
  }
}
