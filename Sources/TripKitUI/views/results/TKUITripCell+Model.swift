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
    let segments: [TKUITripSegmentDisplayable]
    var primaryAction: String?
    var accessibilityLabel: String?
  }
  
}

extension TKUITripCell.Model {
  @MainActor
  init(_ trip: Trip, allowFading: Bool, isArriveBefore: Bool? = nil) {
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
      segments: trip.segments(with: .inSummary),
      primaryAction: primaryAction?.title,
      accessibilityLabel: trip.accessibilityLabel
    )
  }
  
  var primaryTimeString: String? {
    guard !hideExactTimes else { return nil }
    return TKUITripCell.Formatter.primaryTimeString(
      departure: departure,
      arrival: arrival,
      departureTimeZone: departureTimeZone,
      arrivalTimeZone: arrivalTimeZone,
      focusOnDuration: focusOnDuration,
      isArriveBefore: isArriveBefore
    )
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
