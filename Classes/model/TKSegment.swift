//
//  TKSegment.swift
//  Pods
//
//  Created by Adrian Schoenig on 31/10/16.
//
//

import Foundation

extension TKSegment {
  
  /// Validates the segment, to make sure it's in a consistent state.
  /// If it's in an inconsistent state, many things can go wrong. You might
  /// want to add calls to this method to assertions and precondition checks.
  public func validate() -> Bool {
    // Segments need a trip
    guard let trip = trip else { return false }
    
    // A segment should be in its trip's segments
    guard let _ = trip.segments().index(of: self) else { return false }
    
    // Passed all checks
    return true
  }
  
  
  public func determineRegions() -> [SVKRegion] {
    guard let start = self.start?.coordinate, let end = self.end?.coordinate else { return [] }
    
    return SVKRegionManager.sharedInstance().localRegions(start: start, end: end)
  }
  
  
  /// Test if this segment has at least the specific length.
  ///
  /// - note: public transport will always return `true` to this.
  public func hasVisibility(_ type: STKTripSegmentVisibility) -> Bool {
    switch self.order() {
    case .start: return type == .inDetails
    case .regular: return self.template().visibility.intValue > type.rawValue
    case .end: return type != .inSummary
    }
  }
}

// MARK: - Vehicles

extension TKSegment {
  
  public var usesVehicle: Bool {
    if template().isSharedVehicle() {
      return true
    } else if reference?.vehicleUUID != nil {
      return true
    } else {
      return false
    }
  }
  
  /// - Parameter vehicles: List of the user's vehicles
  /// - Returns: The used vehicle (if there are any) in SkedGo API-compatible form
  public func usedVehicle(fromAll vehicles: [STKVehicular]) -> [AnyHashable: Any]? {
    if template().isSharedVehicle() {
      return reference?.sharedVehicleData
    }
    
    if let vehicle = reference?.vehicle(fromAllVehicles: vehicles) {
      return STKVehicularHelper.skedGoReferenceDictionary(forVehicle: vehicle)
    } else {
      return nil
    }
  }
  
  
  /// The private vehicle type used by this segment (if any)
  public var privateVehicleType: STKVehicleType {
    guard let identifier = modeIdentifier() else { return .none }
    
    switch identifier {
    case SVKTransportModeIdentifierCar: return .car
    case SVKTransportModeIdentifierBicycle: return .bicycle
    case SVKTransportModeIdentifierMotorbike: return .motorbike
    default: return .none
    }
  }
  
  /// - Parameter vehicle: Vehicle to assign to this segment. Only takes affect if its of a compatible type.
  public func assignVehicle(_ vehicle: STKVehicular?) {
    guard privateVehicleType == vehicle?.vehicleType() else { return }
    
    reference?.setVehicle(vehicle)
  }
  
}

