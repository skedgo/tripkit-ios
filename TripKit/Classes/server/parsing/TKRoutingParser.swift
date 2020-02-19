//
//  TKRoutingParser.swift
//  TripKit
//
//  Created by Adrian Schoenig on 31/08/2016.
//
//

import Foundation

/// :nodoc:
extension TKRoutingParser {
  @objc public static func matchingSegment(in trip: Trip, order: TKSegmentOrdering, first: Bool) -> TKSegment {
    
    var match: TKSegment? = nil
    for segment in (trip as TKTrip).segments(with: .inDetails) {
      if let tks = segment as? TKSegment, tks.order == order {
        match = tks
        if first {
          break;
        }
      }
    }
    return match!
  }

  /// Helper method to fill in a request wich the specified location.
  ///
  /// Typically used on requests that were created as part of a previous call to
  /// `parseAndAddResult`. All parameters except `request` are optional.
  @objc public static func populate(_ request: TripRequest, start: MKAnnotation?, end: MKAnnotation?, leaveAfter: Date?, arriveBy: Date?, queryJSON: [String: Any]? = nil) -> Bool {

    guard let trip = request.trips.first else {
      return false
    }
    
    if let start = start, let named = TKNamedCoordinate.namedCoordinate(for: start) {
      request.fromLocation = named
    } else if let json = queryJSON?["from"] as? [String: Any], let from = TKParserHelper.namedCoordinate(for: json) {
      request.fromLocation = from
    } else {
      let segment = matchingSegment(in: trip, order: .regular, first: true)
      guard let start = segment.start?.coordinate else { return false }
      request.fromLocation = TKNamedCoordinate(coordinate: start)
    }
    if let end = end, let named = TKNamedCoordinate.namedCoordinate(for: end) {
      request.toLocation = named
    } else if let json = queryJSON?["to"] as? [String: Any], let to = TKParserHelper.namedCoordinate(for: json) {
      request.toLocation = to
    } else {
      let segment = matchingSegment(in: trip, order: .regular, first: false)
      guard let end = segment.end?.coordinate else { return false }
      request.toLocation = TKNamedCoordinate(coordinate: end)
    }
    
    if let leaveAfter = leaveAfter {
      request.departureTime = leaveAfter
      request.timeType = NSNumber(value: TKTimeType.leaveAfter.rawValue)
    }
    
    if let arriveBy = arriveBy {
      request.arrivalTime = arriveBy
      request.timeType = NSNumber(value: TKTimeType.arriveBefore.rawValue) // can overwrite leave after
    }
    
    if arriveBy == nil && leaveAfter == nil {
      if let trip = request.trips.first {
        let firstRegular = matchingSegment(in: trip, order: .regular, first: true)
        request.departureTime = firstRegular.departureTime
        request.timeType = NSNumber(value: TKTimeType.leaveAfter.rawValue)
      } else {
        request.timeType = NSNumber(value: TKTimeType.leaveASAP.rawValue)
      }
    }
    
    request.tripGroups?.first?.adjustVisibleTrip()
    return true
  }
  
}
