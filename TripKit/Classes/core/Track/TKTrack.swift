//
//  TKTrack.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation
import MapKit

/**
 A `TKTrack` is an object representing a list of events (and similar objects) taking place one after the other - each of which that the user attends.
 */
@objc
public protocol TKTrack : NSObjectProtocol {
  
  /**
   Start time of the track. Note that items can start before this.
   */
  var startDate: Date { get }
  
  /**
   End time of the track. Note that items can end after this time.
   */
  var endDate: Date { get }
  
  /**
   Content of the track. Each conforming to `TKTrackItem`
   */
  var items: [TKTrackItem] { get }
  
  /**
   Pointer to the previous track if they are chained together.
   */
  var previous: TKTrack? { get }
  
  /**
   Pointer to the next track if they are chained together.
   */
  var next: TKTrack? { get }
  
  var startTimeZone: TimeZone? { get }
  
  var isEditing: Bool { get set }
}

extension TKTrack {
  
  var previous: TKTrack? { return nil }
  
  var next: TKTrack? { return nil }
  
  var startTimeZone: TimeZone? { return nil }
  
  var isEditing: Bool {
    get { return false }
    set { }
  }
  
}

@objc
public enum TKTrackItemStatus : Int {
  
  case none
  
  case canceled
  
  case excluded
  
  /// Item does not fit track; typically decided by algorithm
  case cannotFit
}

/**
 A `TKTrackItem` is something that's on the track of a user for a given day/track. Typically these have locations and times, but both are optional.
 */
@objc
public protocol TKTrackItem : NSObjectProtocol {
  
  var title: String { get }

  /**
   Start time which is used to display information about this track item, but it also used to guess the times of other track items which have no time information.
   
   If this is not nil, a positive duration is required.
   */
  var startDate: Date? { get }
  
  /**
   The duration of this item. If you want this to be treated as no known or fixed duration, return something negative
   */
  var duration: TimeInterval { get }
  
  /**
   Time zone where this track item takes place.
   */
  var timeZone: TimeZone? { get }

  /**
   Address used for resolving.
   */
  var address: String? { get }
  
  /**
   The status of the item, indicating if it's canceled (typically not in the user's control), excluded (typically by the user) or doesn't fit (decided by algorithm)
   */
  var trackItemStatus: TKTrackItemStatus { get }
  
  /**
   Where this track item takes place.
   */
  var mapAnnotation: MKAnnotation? { get }
  
  /**
   The identifier used for exclusion and effective start/end date. It can't be the standard identifier of a series, but should be a combination of that and the date.
   */
  var itemIdentifier: String? { get }
  
}

/**
 Protocol for displaying track items in the UI.
 */
@objc
public protocol TKTrackItemDisplayable: TKTrackItem {

  /**
   If the item should be considered as content, e.g., having any item with a content will mark a date on the calendar
   */
  var considerAsContent: Bool { get }
  
  /**
   If the start/end times for this item should usually be hidden (e.g., for "home" or where you're staying).
   */
  var hideTimes: Bool { get }
  
  /**
   If the address for this item should usually be hidden (e.g., for "work" or "home" where you know where they are anyway).
   */
  var hideAddress: Bool { get }
  
  /**
   The name of the image that will be placed on map pins and on the track
   */
  var trackIcon: TKImage? { get }
  
  /**
   If the item should be displayed faded out, e.g., for examples or because it's in the past.
   */
  var showFadedOut: Bool { get }
  
  /**
   A color for this track item, say, for events it's their calendar's colour. This is ignored if `bannerIconImage` is implemented and returns not `nil`.
   */
  var bannerIconColor: TKColor? { get }
  
  
  /**
   A little image for this track item, say, a house for home. Takes precedence over `bannerIconColor`.
   */
  var bannerIconImage: TKImage? { get }

}

/**
 A kind of `TKTrackItem` that represents a trip.
 */
@objc
public protocol TKTripTrackItem : TKTrackItem {
  
  /**
   @return The trip
   */
  var trip: TKTrip! { get }
  
  /**
   The route for items that represent movement. It's an array because it can be multi-modal.
   */
  var routes: [TKDisplayableRoute] { get }
  
  /**
   @note You should implement this if you implement `routes`.
   @return Where this route of this track starts.
   */
  var routeStart: MKAnnotation { get }
  
  /**
   @note You should implement this if you implement `routes`.
   @return Where this route of this track ends.
   */
  var routeEnd: MKAnnotation { get }
  
  /**
   If the trip is locked in and shouldn't get replaced automatically.
   */
  var isLockedIn: Bool { get }
  
  /**
   - returns: If the specified location is compatible with the trip both in terms of location and in terms of time
   */
  @objc(containsLocation:atTime:)
  func contains(_ location: CLLocation, at time: Date) -> Bool
}

@available(*, unavailable, renamed: "TKTrack")
public typealias SGTrack = TKTrack

@available(*, unavailable, renamed: "TKTrackItem")
public typealias SGTrackItem = TKTrackItem

