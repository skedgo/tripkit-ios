//
//  TKTripPattern.swift
//  TripKit
//
//  Created by Adrian Schoenig on 14/09/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

#if canImport(CoreLocation)
import CoreLocation
#endif


/// Simple dictionary representing a segment that can be
/// used as input to `TKWaypointRouter`.
public typealias TKSegmentPattern = TKWaypointRouter.Segment


public enum TKTripPattern {
  
  /// - Returns: The trip pattern for a trip
  public static func pattern(for trip: Trip) -> [TKSegmentPattern] {
    return trip.segments.compactMap(\.pattern)
  }

#if canImport(CoreLocation)
  public static func od(for pattern: [TKSegmentPattern]) -> (o: CLLocationCoordinate2D, d: CLLocationCoordinate2D)? {
    if case .coordinate(let start) = pattern.first?.start,
       case .coordinate(let end) = pattern.last?.end {
      return (start, end)
    } else {
      return nil
    }
  }
#endif
  
#if canImport(CoreData)
  public static func modeLabels(for trip: Trip) -> [String] {
    return trip.segments.compactMap { segment in
      guard !segment.isStationary else { return nil }
      if let info = segment.modeInfo {
        return info.alt
      } else if let mode = segment.modeIdentifier {
        return TKRegionManager.shared.title(forModeIdentifier: mode)
      } else {
        return nil
      }
    }
  }
#endif
  
  public static func modeLabels(for pattern: [TKSegmentPattern]) -> [String] {
    return pattern.compactMap { pattern in
      if let mode = pattern.modes.first {
        return TKRegionManager.shared.title(forModeIdentifier: mode)
      } else {
        return nil
      }
    }
  }
  
}


#if canImport(CoreData)

extension TKSegment {
  
  fileprivate var pattern: TKSegmentPattern? {
    guard !isStationary else { return nil }
    guard let mode = modeIdentifier else {
      assertionFailure("Segment is missing mode: \(self)")
      return nil
    }
    guard let start = start, let end = end else {
      assertionFailure("Non-stationary segment without start & stop")
      return nil
    }

    // Previously also had:
//    pattern["preferredPublic"] = isPublicTransport ? modeInfo?.identifier : nil
    
    return .init(
      start: .coordinate(start.coordinate),
      end: .coordinate(end.coordinate),
      modes: [mode]
    )
  }
  
}

#endif
