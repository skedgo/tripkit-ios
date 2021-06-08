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
  /// `parseAndAddResult`.
  ///
  /// Also sets time type depending on whether `leaveAfter` and/or `arriveBy` are
  /// provided. If both a provided, `arriveBy` takes precedence.
  ///
  /// - Parameters:
  ///   - request: The request to populate it's from/to/time information
  ///   - start: New `fromLocation`. If not supplied, will be inferred from a random trip
  ///   - end: New `toLocation`. If not supplied, will be inferred from a random trip
  ///   - leaveAfter: Preferred departure time from `start`
  ///   - arriveBy: Preffered arrive-by time at `end`
  /// - Returns: If the request did get updated successfully
  @objc
  @discardableResult
  public static func populate(_ request: TripRequest, start: MKAnnotation?, end: MKAnnotation?, leaveAfter: Date?, arriveBy: Date?, queryJSON: [String: Any]? = nil) -> Bool {

    guard let trip = request.trips.first else {
      return false
    }
    
    if let start = start, start.coordinate.isValid {
      let named = TKNamedCoordinate.namedCoordinate(for: start)
      request.fromLocation = named
    } else if let json = queryJSON?["from"] as? [String: Any], let from = TKParserHelper.namedCoordinate(for: json) {
      request.fromLocation = from
    } else {
      let segment = matchingSegment(in: trip, order: .regular, first: true)
      guard let start = segment.start?.coordinate else { return false }
      request.fromLocation = TKNamedCoordinate(coordinate: start)
    }
    if let end = end, end.coordinate.isValid {
      let named = TKNamedCoordinate.namedCoordinate(for: end)
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
      request.type = .leaveAfter
    }
    if let arriveBy = arriveBy {
      request.arrivalTime = arriveBy
      request.type = .arriveBefore // can overwrite leave after
    }
    
    if arriveBy == nil && leaveAfter == nil {
      if let depart = queryJSON?["depart"] as? String, let time = ISO8601DateFormatter().date(from: depart) {
        request.departureTime = time
        request.type = .leaveAfter
      } else if let arrive = queryJSON?["arrive"] as? String, let time = ISO8601DateFormatter().date(from: arrive) {
        request.arrivalTime = time
        request.type = .arriveBefore
      } else if let trip = request.trips.first {
        let firstRegular = matchingSegment(in: trip, order: .regular, first: true)
        request.departureTime = firstRegular.departureTime
        request.type = .leaveAfter
      } else {
        request.type = .leaveASAP
      }
    }
    
    request.tripGroups?.first?.adjustVisibleTrip()
    return true
  }
  
}
