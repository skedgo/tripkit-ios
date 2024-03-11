//
//  TKWheelchairAccessibility.swift
//  TripKit
//
//  Created by Adrian Schönig on 24.12.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

/// Indicates accessibility of services, stops, footpaths for wheelchair users (also useful for prams, etc.)
@objc
public enum TKWheelchairAccessibility: Int {
  /// Known to be accessible
  case accessible
  
  /// Known to not be accessible
  case notAccessible
  
  /// Unknown whether it's accessible or not
  case unknown
  
  /// Localised title
  public var title: String {
    switch self {
    case .accessible:
      return Loc.WheelchairAccessible
    case .notAccessible:
      return Loc.WheelchairNotAccessible
    case .unknown:
      return Loc.WheelchairAccessibilityUnknown
    }
  }
  
  /// :nodoc:
  public init(bool: Bool?) {
    switch bool {
    case .some(true):   self = .accessible
    case .some(false):  self = .notAccessible
    case .none:         self = .unknown
    }
  }
  
  /// Merges two wheelchair accessibility values
  ///
  /// If either is known to be inaccessible, this will return `.notAccessible`. If both are known be accessible, this will return `.accessible`. Otherwise, if either is unknown, it'll depends on the `preferUnknown`.
  ///
  /// - Parameter preferUnknown:For something that is not known to inaccessible and either  has an unknown status, this determines whether it should return `.unknown` or `.accessible`
  public func combine(with other: TKWheelchairAccessibility, preferUnknown: Bool = false) -> TKWheelchairAccessibility {
    switch (preferUnknown, self, other) {

    // Either being not accessible rules them all
    case (_, .notAccessible, _),
         (_, _, .notAccessible):  return .notAccessible

    // Next, if we prefer unknown, unknown rules accessible
    case (_, .unknown, .unknown),
         (true, .unknown, _),
         (true, _, .unknown):     return .unknown

    // Otherwise, it's known
    case (_, .accessible, _),
         (_, _, .accessible):     return .accessible
    }
  }
}

// MARK: - Wheelchair accessibility extensions

public extension StopLocation {
  /// Accessibility of the stop. Note that whether you can get onto a specific service it'll also depend on the accessibility of the service. See `StopVisits.getWheelchairAccessibility()`
  internal(set) var wheelchairAccessibility: TKWheelchairAccessibility {
    get {
      return TKWheelchairAccessibility(bool: wheelchairAccessible?.boolValue)
    }
    set {
      switch newValue {
      case .accessible:
        wheelchairAccessible = NSNumber(value: true)
      case .notAccessible:
        wheelchairAccessible = NSNumber(value: false)
      case .unknown:
        wheelchairAccessible = nil
      }
    }
  }
}

public extension Service {
  /// Accessibility of the service, i.e., a property of the vehicle. Note that whether you can get on the
  /// service will also depend on the accessibility of the stop. See `StopVisits.getWheelchairAccessibility()`
  internal(set) var wheelchairAccessibility: TKWheelchairAccessibility {
    get {
      switch (isWheelchairAccessible, isWheelchairInaccessible) {
      case (false, false): return .unknown
      case (true, false): return .accessible
      case (false, true): return .notAccessible
      
      case (true, true):
        assertionFailure("Invalid accessibility state")
        return .unknown
      }
    }
    
    set {
      switch newValue {
      case .accessible:
        isWheelchairAccessible = true
        isWheelchairInaccessible = false
      case .notAccessible:
        isWheelchairAccessible = false
        isWheelchairInaccessible = true
      case .unknown:
        isWheelchairAccessible = false
        isWheelchairInaccessible = false
      }
    }
  }
  
  /// :nodoc:
  @objc
  func _setWheelchairAccessibility(_ number: NSNumber?) {
    self.wheelchairAccessibility = TKWheelchairAccessibility(bool: number?.boolValue)
  }
}

public extension StopVisits {
  
  /// Wheelchair accessibility of a service at a given stop
  ///
  /// If either the stop and the service are known to be inaccessible, this will return `.notAccessible`. If at least one is known to be accessible, this will return `.accessible`
  var wheelchairAccessibility: TKWheelchairAccessibility {
    var accessibility = stop.wheelchairAccessibility.combine(with: service.wheelchairAccessibility, preferUnknown: false)
    
    if let dls = self as? DLSEntry {
      accessibility = accessibility.combine(with: dls.endStop.wheelchairAccessibility, preferUnknown: false)
    }
    
    return accessibility
  }
}

public extension TKSegment {
  /// Wheelchair accessibility of the segment, returns `nil` if doesn't apply
  /// to this kind of segment
  var wheelchairAccessibility: TKWheelchairAccessibility? {
    reference?.wheelchairAccessibility
  }
}

/// :nodoc:
extension SegmentReference {
  
  var wheelchairAccessibility: TKWheelchairAccessibility {
    get {
      switch (isWheelchairAccessible, isWheelchairInaccessible) {
      case (false, false): return .unknown
      case (true, false): return .accessible
      case (false, true): return .notAccessible
      
      case (true, true):
        assertionFailure("Invalid accessibility state")
        return .unknown
      }
    }
    
    set {
      switch newValue {
      case .accessible:
        isWheelchairAccessible = true
        isWheelchairInaccessible = false
      case .notAccessible:
        isWheelchairAccessible = false
        isWheelchairInaccessible = true
      case .unknown:
        isWheelchairAccessible = false
        isWheelchairInaccessible = false
      }
    }
  }
  
  /// :nodoc:
  @objc
  func _setWheelchairAccessibility(_ number: NSNumber?) {
    self.wheelchairAccessibility = TKWheelchairAccessibility(bool: number?.boolValue)
  }
  
}
