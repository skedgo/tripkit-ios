//
//  TKUITripSegmentDisplayable.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 17/6/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKit

public protocol TKUITripSegmentDisplayable {
  
  var tripSegmentModeColor: TKColor? { get }
  
  var tripSegmentModeImage: TKImage? { get }
  
  var tripSegmentModeImageURL: URL? { get }
  
  /// If true, then `tripSegmentModeImageURL` should be treated as a template
  /// image and have an appropriate colour applied to it.
  var tripSegmentModeImageIsTemplate: Bool { get }

  /// If true, `tripSegmentModeImageURL` points at a brand image and should be
  /// shown next to `tripSegmentModeImage`; if `false` it shoud replace  it.
  var tripSegmentModeImageIsBranding: Bool { get }

  /// The icon to display on top of a mode icon to indicate issues with the
  /// mode itself, e.g., a service being cancelled or a car share vehicle
  /// not being available.
  var tripSegmentModeInfoIconType: TKInfoIconType { get }

  /// The icon to display next to the sub-title to indicate secondary issues
  /// with the segment, e.g., an alert icon for real-time traffic issues.
  var tripSegmentSubtitleIconType: TKInfoIconType { get }

  /// Brief accessibility label for the segmgent in the trip segment view
  var tripSegmentAccessibilityLabel: String? { get }

  /// A title to show next to the mode image.
  var tripSegmentModeTitle: String? { get }
  
  /// A subtitle to show next to the mode image.
  var tripSegmentModeSubtitle: String? { get }
  
  /// The segment's departure time, if it's a fixed time, e.g., public transport
  var tripSegmentFixedDepartureTime: Date? { get }
  
  /// Time zone of the segment. Required if `tripSegmentFixedDepartureTime` is implemented.
  var tripSegmentTimeZone: TimeZone? { get }
  
  var tripSegmentTimesAreRealTime: Bool { get }
  
  /// Wheelchair accessibility of the segment. If it doesn't apply, just return `.unknown`,
  /// as an `.unknown` value will always be ignored.
  var tripSegmentWheelchairAccessibility: TKWheelchairAccessibility { get }
}

public extension TKUITripSegmentDisplayable {
  var tripSegmentModeColor: TKColor? { nil }
  var tripSegmentModeImage: TKImage? { nil }
  var tripSegmentModeImageURL: URL? { nil }
  var tripSegmentModeImageIsTemplate: Bool { false }
  var tripSegmentModeImageIsBranding: Bool { false }
  var tripSegmentModeInfoIconType: TKInfoIconType { .none }
  var tripSegmentSubtitleIconType: TKInfoIconType { .none }
  var tripSegmentModeTitle: String? { nil }
  var tripSegmentModeSubtitle: String? { nil }
  var tripSegmentFixedDepartureTime: Date? { nil }
  var tripSegmentTimeZone: TimeZone? { nil }
  var tripSegmentTimesAreRealTime: Bool { false }
  var tripSegmentWheelchairAccessibility: TKWheelchairAccessibility { .unknown }
}

extension TKSegment: TKUITripSegmentDisplayable {}
