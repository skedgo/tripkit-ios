//
//  STKTripAndSegments.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

@objc
public enum STKTripCostType : Int {
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
public enum STKTripSegmentVisibility : Int {
  
  /// never visible in UI
  case hidden
  
  case inDetails
  
  case onMap
  
  case inSummary
}

@objc
public protocol STKTrip : NSObjectProtocol {
  
  /// @return Mapping of boxed `STKTripCostType` to strings of their values.
  var costValues: [NSNumber : String] { get }
  
  var departureTime: Date { get }
  
  var arrivalTime: Date { get }
  
  var departureTimeZone: TimeZone { get }
  
  var departureTimeIsFixed: Bool { get }
  
  var isArriveBefore: Bool { get }
  
  @objc(segmentsWithVisibility:)
  func segments(with type: STKTripSegmentVisibility) -> [STKTripSegment]
  
  func mainSegment() -> STKTripSegment
  
  /// Short title describing the trip's purpose, e.g., "To work"
  var tripPurpose: String? { get }
  
  
  /// Whether this trip has at least one reminder and the reminder icon should be displayed.
  var hasReminder: Bool { get set }
  
  
  /// Time zone of the arrival time, if different from `departureTimeZone`
  var arrivalTimeZone: TimeZone? { get }
}

/// Protocol with minimum details to display the high-level details of a segment. An example use of this is `SGTripSegmentsView` in `TripKitUI`.
@objc
public protocol STKTripSegmentDisplayable : NSObjectProtocol {
  
  var tripSegmentModeColor: SGKColor? { get }
  
  var tripSegmentModeImage: SGKImage? { get }
  
  var tripSegmentModeImageURL: URL? { get }
  
  var tripSegmentModeInfoIconType: STKInfoIconType { get }
  
  
  /// - todo: This doubles up with `tripSegmentModeInfo`
  /// - returns: A title to show next to the mode image.
  var tripSegmentModeTitle: String? { get }
  
  /// - todo: This doubles up with `tripSegmentModeInfo`
  /// - returns: A subtitle to show next to the mode image.
  var tripSegmentModeSubtitle: String? { get }
  
  /// The segment's departure time, if it's a fixed time, e.g., public transport
  var tripSegmentFixedDepartureTime: Date? { get }
  
  /// Time zone of the segment. Required if `tripSegmentFixedDepartureTime` is implemented.
  var tripSegmentTimeZone: TimeZone? { get }
  
  var tripSegmentTimesAreRealTime: Bool { get }
  
  var tripSegmentIsWheelchairAccessible: Bool { get }
}

@objc
public protocol STKTripSegment : STKTripSegmentDisplayable {
  
  var tripSegmentInstruction: String { get }
  
  /// A string to display as this segment's main value (e.g., the formatted distance or price) or a date for when this segment leaves.
  var tripSegmentMainValue: Any { get }
  
  var tripSegmentModeInfo: ModeInfo? { get }
  
  /// A short detail expanding on `tripSegmentInstruction`.
  var tripSegmentDetail: String? { get }
}


extension STKTrip {
  var isArriveBefore: Bool { return false }
  var costValues: [NSNumber : String] { return [:] }
  var tripPurpose: String? { return nil }
  var hasReminder: Bool { return false }
  var arrivalTimeZone: TimeZone? { return nil }
}

extension STKTripSegmentDisplayable {
  var tripSegmentModeColor: SGKColor? { return nil }
  var tripSegmentModeImage: SGKImage? { return nil }
  var tripSegmentModeImageURL: URL? { return nil }
  var tripSegmentModeInfoIconType: STKInfoIconType { return .none }
  var tripSegmentModeTitle: String? { return nil }
  var tripSegmentModeSubtitle: String? { return nil }
  var tripSegmentFixedDepartureTime: Date? { return nil }
  var tripSegmentTimeZone: TimeZone? { return nil }
  var tripSegmentTimesAreRealTime: Bool { return false }
  var tripSegmentIsWheelchairAccessible: Bool { return false }
}

extension STKTripSegment {
  var tripSegmentModeInfo: ModeInfo? { return nil }
  var tripSegmentDetail: String? { return nil }
}
