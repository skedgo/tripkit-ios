//
//  TKTripPattern.swift
//  TripKit
//
//  Created by Adrian Schoenig on 14/09/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import CoreLocation


/// Simple dictionary representing a segment that can be
/// used as input to `TKWaypointRouter`.
public typealias TKSegmentPattern = [String: Any]


// Pure Swift this would be a caseless enum
public class TKTripPattern: NSObject {
  
  private override init() { super.init() }
  
  
  /// - Returns: The trip pattern for a trip
  @objc(tripPatternForTrip:)
  public static func pattern(for trip: Trip) -> [TKSegmentPattern] {
    return trip.segments().compactMap { $0.pattern }
  }
  

  public static func od(for pattern: [TKSegmentPattern]) -> (o: CLLocationCoordinate2D, d: CLLocationCoordinate2D)? {
    
    guard
      let startString = pattern.first?["start"] as? String,
      let endString = pattern.last?["end"] as? String,
      let start = SVKParserHelper.coordinate(forRequest: startString),
      let end = SVKParserHelper.coordinate(forRequest: endString)
      else { return nil }
    
    return (start, end)
  }
  
}


extension TKSegment {
  
  fileprivate var pattern: TKSegmentPattern? {
    guard !isStationary() else { return nil }
    guard let mode = modeIdentifier() else {
      assertionFailure("Segment is missing mode: \(self)")
      return nil
    }
    guard let start = start, let end = end else {
      assertionFailure("Non-stationary segment without start & stop")
      return nil
    }
    
    var pattern: [String: Any] = [
      "start":  SVKParserHelper.requestString(for: start),
      "end":    SVKParserHelper.requestString(for: end),
      "modes":  [mode]
    ]
    
    pattern["alt"] = modeInfo()?.alt
    pattern["preferredPublic"] = isPublicTransport() ? modeInfo()?.identifier : nil
    return pattern
  }
  
}


extension SVKParserHelper {
  
  /// Inverse of `SVKParserHelper.requestString(for:)`
  class func coordinate(forRequest string: String) -> CLLocationCoordinate2D? {
    
    let pruned = string
      .replacingOccurrences(of: "(", with: "")
      .replacingOccurrences(of: ")", with: "")
    
    let numbers = pruned.components(separatedBy: ",")
    if numbers.count != 2 {
      return nil
    }
    
    guard
      let lat = CLLocationDegrees(numbers[0]),
      let lng = CLLocationDegrees(numbers[1])
      else { return nil }
    
    return CLLocationCoordinate2D(latitude: lat, longitude: lng)
  }
  
}
