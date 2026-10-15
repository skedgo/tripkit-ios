//
//  TKUITripCell+Model.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 9/8/2024.
//  Copyright © 2024 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKit

extension TKUITripCell {
  
  struct Model {
    let departure: Date
    let arrival: Date
    let departureTimeZone: TimeZone
    let arrivalTimeZone: TimeZone
    let focusOnDuration: Bool
    let isArriveBefore: Bool
    let showFaded: Bool
    let isCancelled: Bool
    let hideExactTimes: Bool
    
    /// How many calendar days the trip is from the requested time, e.g., `1` for
    /// a trip on the day after, which can happen for services that don't run
    /// every day.
    var dayOffset: Int = 0
    
    let segments: [TKUITripSegmentDisplayable]
    var mainSegmentIndex: Int? = nil
    var primaryAction: String?
    var accessibilityLabel: String?
  }
  
}

extension TKUITripCell.Model {
  @MainActor
  init(_ trip: Trip, allowFading: Bool, isArriveBefore: Bool? = nil) {
    let segments = trip.segments(with: .inSummary)
    let mainSegment = trip.mainSegment
    let primaryAction = TKUITripOverviewCard.config.tripActionsFactory?(trip).first(where: { $0.priority >= TKUITripOverviewCard.DefaultActionPriority.book.rawValue })
    
    self.init(
      departure: trip.departureTime,
      arrival: trip.arrivalTime,
      departureTimeZone: trip.departureTimeZone,
      arrivalTimeZone: trip.arrivalTimeZone ?? trip.departureTimeZone,
      focusOnDuration: !trip.departureTimeIsFixed,
      isArriveBefore: isArriveBefore ?? trip.isArriveBefore,
      showFaded: allowFading && trip.showFaded,
      isCancelled: trip.isCanceled,
      hideExactTimes: trip.hideExactTimes,
      dayOffset: Self.dayOffset(of: trip, isArriveBefore: isArriveBefore ?? trip.isArriveBefore),
      segments: segments,
      mainSegmentIndex: segments.firstIndex { $0 === mainSegment },
      primaryAction: primaryAction?.title,
      accessibilityLabel: trip.accessibilityLabel
    )
  }
  
  @MainActor
  private static func dayOffset(of trip: Trip, isArriveBefore: Bool) -> Int {
    guard trip.departureTimeIsFixed, let request = trip.request else { return 0 }
    let requested = request.time ?? Date() // nil for "leave now"
    if isArriveBefore {
      return TKUITripCell.Formatter.dayOffset(of: trip.arrivalTime, from: requested, in: trip.arrivalTimeZone ?? trip.departureTimeZone)
    } else {
      return TKUITripCell.Formatter.dayOffset(of: trip.departureTime, from: requested, in: trip.departureTimeZone)
    }
  }
  
  var primaryTimeString: String? {
    guard !hideExactTimes else { return nil }
    return TKUITripCell.Formatter.primaryTimeString(
      departure: departure,
      arrival: arrival,
      departureTimeZone: departureTimeZone,
      arrivalTimeZone: arrivalTimeZone,
      focusOnDuration: focusOnDuration,
      isArriveBefore: isArriveBefore,
      showWeekday: dayOffset != 0
    )
  }
  
  /// E.g., "+1 day", if the trip isn't on the same day as the requested time
  var dayOffsetString: String? {
    guard !hideExactTimes else { return nil }
    return TKUITripCell.Formatter.dayOffsetString(dayOffset)
  }
  
  var secondaryTimeString: String? {
    guard !hideExactTimes else { return nil }
    return TKUITripCell.Formatter.secondaryTimeString(
      departure: departure,
      arrival: arrival,
      departureTimeZone: departureTimeZone,
      arrivalTimeZone: arrivalTimeZone,
      focusOnDuration: focusOnDuration,
      isArriveBefore: isArriveBefore
    )
  }
}
