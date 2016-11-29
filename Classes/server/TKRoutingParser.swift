//
//  TKRoutingParser.swift
//  Pods
//
//  Created by Adrian Schoenig on 31/08/2016.
//
//

import Foundation

import SGCoreKit

extension TKRoutingParser {
  public static func matchingSegment(in trip: Trip, order: TKSegmentOrdering, first: Bool) -> TKSegment {
    
    var match: TKSegment? = nil
    for segment in (trip as STKTrip).segments(with: .inDetails) {
      if let tks = segment as? TKSegment, tks.order() == order {
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
  public static func populate(_ request: TripRequest, start: MKAnnotation?, end: MKAnnotation?, leaveAfter: Date?, arriveBy: Date?) -> Bool {
    
    guard let trip = request.trips?.first else {
      return false
    }
    
    if let start = start, let named = SGKNamedCoordinate.namedCoordinate(for: start) {
      request.fromLocation = named
    } else {
      let segment = matchingSegment(in: trip, order: .regular, first: true)
      guard let start = segment.start?.coordinate else { return false }
      request.fromLocation = SGKNamedCoordinate(coordinate: start)
    }
    if let end = end, let named = SGKNamedCoordinate.namedCoordinate(for: end) {
      request.toLocation = named
    } else {
      let segment = matchingSegment(in: trip, order: .regular, first: false)
      guard let end = segment.end?.coordinate else { return false }
      request.toLocation = SGKNamedCoordinate(coordinate: end)
    }
    
    if let leaveAfter = leaveAfter {
      request.departureTime = leaveAfter
      request.timeType = NSNumber(value: SGTimeType.leaveAfter.rawValue)
    }
    
    if let arriveBy = arriveBy {
      request.arrivalTime = arriveBy
      request.timeType = NSNumber(value: SGTimeType.arriveBefore.rawValue) // can overwrite leave after
    }
    
    if arriveBy == nil && leaveAfter == nil {
      if let trip = request.trips?.first {
        let firstRegular = matchingSegment(in: trip, order: .regular, first: true)
        request.departureTime = firstRegular.departureTime
        request.timeType = NSNumber(value: SGTimeType.leaveAfter.rawValue)
      } else {
        request.timeType = NSNumber(value: SGTimeType.leaveASAP.rawValue)
      }
    }
    
    if let trip = request.trips?.first {
      trip.setAsPreferredTrip()
    }
    return true
  }
}
