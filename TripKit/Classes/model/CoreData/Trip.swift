//
//  Trip.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension Trip {
  
  @objc public var primaryCostType: TKTripCostType {
    if departureTimeIsFixed {
      return .time
    } else if isExpensive {
      return .price
    } else {
      return .duration
    }
  }
  
  /// Checks for intermodality. Ignores very short walks and, optionally, all walks.
  ///
  /// - Parameter ignoreWalking: If walks should be ignored completely
  /// - Returns: If trip is mixed modal (aka intermodmal)
  @objc(isMixedModalIgnoringWalking:)
  public func isMixedModal(ignoreWalking: Bool) -> Bool {
    var previousMode: String? = nil
    for segment in segments {
      guard !segment.isStationary, let mode = segment.modeIdentifier else {
        continue // always ignore stationary segments or modes with identifier
      }
      
      if segment.isWalking, ignoreWalking || !segment.hasVisibility(.inSummary) {
        continue // we always ignore short walks that don't make it into the summary
      }
      if let previous = previousMode, previous != mode {
        return true
      } else {
        previousMode = mode
      }
    }
    return false
  }
  
  private var isExpensive: Bool {
    guard
      let segment = mainSegment() as? TKSegment,
      let identifier = segment.modeIdentifier
      else { return false }
    return TKTransportModes.modeIdentifierIsExpensive(identifier)
  }
  
}


// MARK: - Vehicles

extension Trip {
  
  /// If the trip uses a personal vehicle (non shared) which the user might want to assign to one of their vehicles
  @objc public var usedPrivateVehicleType: TKVehicleType {
    for segment in segments {
      let vehicleType = segment.privateVehicleType
      if vehicleType != .none {
        return vehicleType
      }
    }
    return .none
  }
  
  /// Segments of this trip which do use a private (or shared) vehicle, i.e., those who return something from `usedVehicle`.
  @objc public var vehicleSegments: Set<TKSegment> {
    return segments.reduce(into: Set()) { acc, segment in
      if !segment.isStationary && segment.usesVehicle {
        acc.insert(segment)
      }
    }
  }
  
  /// - Parameter vehicle: The vehicle to assign this trip to. `nil` to reset to a generic vehicle.
  @objc public func assignVehicle(_ vehicle: TKVehicular?) {
    segments.forEach { $0.assignVehicle(vehicle) }
  }
  
}


// MARK: - TKTrip

extension Trip: TKTrip {
  
  @objc public func mainSegment() -> TKTripSegment {
    let hash = mainSegmentHashCode
    if hash > 0 {
      for segment in segments where segment.templateHashCode == hash {
        return segment
      }
      TKLog.warn("Trip", text: "Warning: The main segment hash code should be the hash code of one of the segments. Hash code is: \(hash)")
    }
    
    return inferMainSegment()
  }
  
  public func segments(with type: TKTripSegmentVisibility) -> [TKTripSegment] {
    let filtered = segments.filter { $0.hasVisibility(type) }
    return filtered.isEmpty ? segments : filtered
  }
  
  public var costValues: [NSNumber : String] {
    return accessibleCostValues()
  }
  
  public var isArriveBefore: Bool {
    return request.type == .arriveBefore
  }
  
  public var departureTimeZone: TimeZone {
    return request.departureTimeZone() ?? .current
  }
  
  public var arrivalTimeZone: TimeZone? {
    return request.arrivalTimeZone()
  }
  
  public var tripPurpose: String? {
    return request.purpose
  }
  
}


// MARK: - TKRealTimeUpdatable

/// :nodoc:
extension Trip: TKRealTimeUpdatable {
  public var wantsRealTimeUpdates: Bool {
    guard updateURLString != nil else { return false }
    return wantsRealTimeUpdates(forStart: departureTime, end: arrivalTime, forPreplanning: true)
  }
  
  public var objectForRealTimeUpdates: Any {
    return self
  }
  
  public var regionForRealTimeUpdates: TKRegion {
    return request.startRegion() ?? .international
  }
}


// MARK: - UIActivityItemSource

#if os(iOS)
  
  extension Trip: UIActivityItemSource {
    
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
      return ""
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {

      // Share the full text of the trip, if it's for a mail or we don't also
      // share the trip's URL.
      if activityType == .mail || !TKShareHelper.enableSharingOfURLs {
        return constructPlainText()
      
      } else {
        return nil
      }
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
      return tripPurpose ?? Loc.Trip
    }
    
  }

#endif
