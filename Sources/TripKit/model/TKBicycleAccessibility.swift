//
//  TKBicycleAccessibility.swift
//  TripKit
//
//  Created by Adrian Schönig on 11/3/2024.
//  Copyright © 2024 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

/// Indicates accessibility of services, i.e., if you can take bicycles on public transport
public enum TKBicycleAccessibility: Int {
  /// Known to be accessible
  case accessible
  
  /// Known to not be accessible *or* unknown
  case notAccessible
  
  /// Localised title
  public var title: String {
    switch self {
    case .accessible:
      return Loc.BicycleAccessible
    case .notAccessible:
      return Loc.BicycleNotAccessible
    }
  }
  
  /// :nodoc:
  public init(bool: Bool?) {
    switch bool {
    case .some(true):   self = .accessible
    case .some(false):  self = .notAccessible
    case .none:         self = .notAccessible
    }
  }
}

public extension Service {
  /// Accessibility of the service, i.e., a property of the vehicle. Note that whether you can get on the
  /// service will also depend on the accessibility of the stop. See `StopVisits.getWheelchairAccessibility()`
  internal(set) var bicycleAccessibility: TKBicycleAccessibility {
    get {
      isBicycleAccessible ? .accessible : .notAccessible
    }
    
    set {
      switch newValue {
      case .accessible:
        isBicycleAccessible = true
      case .notAccessible:
        isBicycleAccessible = false
      }
    }
  }
  
  /// :nodoc:
  @objc
  func _setBicycleAccessibility(_ number: NSNumber?) {
    self.bicycleAccessibility = TKBicycleAccessibility(bool: number?.boolValue)
  }
}

public extension TKSegment {
  /// Bicycle accessibility of the segment, returns `nil` if doesn't apply
  /// to this kind of segment
  var bicycleAccessibility: TKBicycleAccessibility? {
    reference?.bicycleAccessibility
  }
}

/// :nodoc:
extension SegmentReference {
  
  var bicycleAccessibility: TKBicycleAccessibility {
    get {
      isBicycleAccessible ? .accessible : .notAccessible
    }
    
    set {
      switch newValue {
      case .accessible:
        isBicycleAccessible = true
      case .notAccessible:
        isBicycleAccessible = false
      }
    }
  }
  
  /// :nodoc:
  @objc
  func _setBicycleAccessibility(_ number: NSNumber?) {
    self.bicycleAccessibility = TKBicycleAccessibility(bool: number?.boolValue)
  }

}
