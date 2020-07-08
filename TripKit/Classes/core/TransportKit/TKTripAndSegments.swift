//
//  STKTripAndSegments.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

@objc
public enum TKTripCostType : Int, Codable {
  case score
  case time
  case duration
  case price
  case carbon
  case hassle
  case walking
  case calories
  case count
}



@objc
public enum TKTripSegmentVisibility : Int, Codable {
  
  /// never visible in UI
  case hidden
  
  case inDetails
  
  case onMap
  
  case inSummary
}

@objc
public protocol TKTrip : NSObjectProtocol {
  
  /// @return Mapping of boxed `TKTripCostType` to strings of their values.
  var costValues: [NSNumber : String] { get }
  
  var departureTime: Date { get }
  
  var arrivalTime: Date { get }
  
  var departureTimeZone: TimeZone { get }
  
  var departureTimeIsFixed: Bool { get }
  
  var isArriveBefore: Bool { get }
  
  @objc(segmentsWithVisibility:)
  func segments(with type: TKTripSegmentVisibility) -> [TKTripSegment]
  
  func mainSegment() -> TKTripSegment
  
  /// Short title describing the trip's purpose, e.g., "To work"
  var tripPurpose: String? { get }
  
  
  /// Whether this trip has at least one reminder and the reminder icon should be displayed.
  var hasReminder: Bool { get set }
  
  
  /// Time zone of the arrival time, if different from `departureTimeZone`
  var arrivalTimeZone: TimeZone? { get }
}

/// Protocol with minimum details to display the high-level details of a segment. An example use of this is `TKUITripSegmentsView` in `TripKitUI`.
@objc
public protocol TKTripSegmentDisplayable : NSObjectProtocol {
  
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

@objc
public protocol TKTripSegment : TKTripSegmentDisplayable {
  
  var tripSegmentInstruction: String { get }
    
  var tripSegmentModeInfo: TKModeInfo? { get }
    
  /// A short detail expanding on `tripSegmentInstruction`.
  var tripSegmentDetail: String? { get }
}


public extension TKTrip {
  var isArriveBefore: Bool { false }
  var costValues: [NSNumber : String] { [:] }
  var tripPurpose: String? { nil }
  var hasReminder: Bool { false }
  var arrivalTimeZone: TimeZone? { nil }
}

public extension TKTripSegmentDisplayable {
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
  var tripSegmentWheelchairAccessibility: TKWheelchairAccessibility? { nil }
}

public extension TKTripSegment {
  var tripSegmentModeInfo: TKModeInfo? { nil }
  var tripSegmentDetail: String? { nil }
}

@available(*, unavailable, renamed: "TKTrip")
public typealias STKTrip = TKTrip

@available(*, unavailable, renamed: "TKTripSegment")
public typealias STKTripSegment = TKTripSegment

@available(*, unavailable, renamed: "TKTripSegmentDisplayable")
public typealias STKTripSegmentDisplayable = TKTripSegmentDisplayable
