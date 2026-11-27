//
//  TKTripFading.swift
//  TripKitAPI
//
//  Created by Adrian Schönig on 27/11/2026.
//  Copyright © 2026 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

/// Which trips are "faded": shown greyed out in results, and not to be
/// treated as a best trip, as they can't be taken as queried.
///
/// Used by both TripKit's `Trip` and by RoutingSpecKit on raw API trips, so
/// that the app and the routing specs agree.
public enum TKTripFading {

  /// How much a trip can miss the queried time and still match the query.
  /// Matches the grace period that the routing server applies.
  public static let queryTolerance: TimeInterval = 60

  public static func isFaded(queryOffset: TimeInterval, isCanceled: Bool, missedBookingWindow: Bool) -> Bool {
    missedBookingWindow   // shuttle, etc., departing too soon
      || isCanceled
      || queryOffset < -queryTolerance  // doesn't match query
  }

  /// Offset in seconds from the queried time, negative if the trip doesn't
  /// satisfy it: the arrival for arrive-by, the departure for leave-after, and
  /// the departure from now otherwise.
  public static func queryOffset(departure: Date, arrival: Date, leaveAfter: Date?, arriveBy: Date?, now: Date = Date()) -> TimeInterval {
    if let arriveBy {
      return arriveBy.timeIntervalSince(arrival)
    } else if let leaveAfter {
      return departure.timeIntervalSince(leaveAfter)
    } else {
      return departure.timeIntervalSince(now)
    }
  }

}

extension TKAPI.Trip {

  /// - Parameter query: The query of the response that this trip is from
  public func isFaded(for query: TKAPI.Query?) -> Bool {
    TKTripFading.isFaded(
      queryOffset: TKTripFading.queryOffset(departure: depart, arrival: arrive, leaveAfter: query?.depart, arriveBy: query?.arrive),
      isCanceled: availability == .canceled,
      missedBookingWindow: availability == .missedPrebookingWindow
    )
  }

}
