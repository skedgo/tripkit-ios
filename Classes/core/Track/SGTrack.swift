//
//  SGTrack.swift
//  Pods
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation
import MapKit

/**
 A `SGTrack` is an object representing a list of events (and similar objects) taking place one after the other - each of which that the user attends.
 */
@objc
public protocol SGTrack : NSObjectProtocol {
  
  /**
   Start time of the track. Note that items can start before this.
   */
  var startDate: Date { get }
  
  /**
   End time of the track. Note that items can end after this time.
   */
  var endDate: Date { get }
  
  /**
   Content of the track. Each conforming to `SGTrackItem`
   */
  var items: [SGTrackItem] { get }
  
  /**
   Pointer to the previous track if they are chained together.
   */
  var previous: SGTrack? { get }
  
  /**
   Pointer to the next track if they are chained together.
   */
  var next: SGTrack? { get }
  
  var startTimeZone: TimeZone? { get }
  
  var isEditing: Bool { get set }
}

extension SGTrack {
  
  var previous: SGTrack? { return nil }
  
  var next: SGTrack? { return nil }
  
  var startTimeZone: TimeZone? { return nil }
  
  var isEditing: Bool {
    get { return false }
    set { }
  }
  
}

@objc
public enum SGTrackItemStatus : Int {
  
  case none
  
  case canceled
  
  case excluded
  
  /// Item does not fit track; typically decided by algorithm
  case cannotFit
}

/**
 A `SGTrackItem` is something that's on the track of a user for a given day/track. Typically these have locations and times, but both are optional.
 */
@objc
public protocol SGTrackItem : NSObjectProtocol {
  
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
  var trackItemStatus: SGTrackItemStatus { get }
  
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
public protocol SGTrackItemDisplayable: SGTrackItem {

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
  var trackIcon: SGKImage? { get }
  
  /**
   If the item should be displayed faded out, e.g., for examples or because it's in the past.
   */
  var showFadedOut: Bool { get }
  
  /**
   A color for this track item, say, for events it's their calendar's colour. This is ignored if `bannerIconImage` is implemented and returns not `nil`.
   */
  var bannerIconColor: SGKColor? { get }
  
  
  /**
   A little image for this track item, say, a house for home. Takes precedence over `bannerIconColor`.
   */
  var bannerIconImage: SGKImage? { get }

}

/**
 A track item that represent a background location, such as the
 user's home or stay in a hotel.
 */
@objc
public protocol SGTrackItemBackgroundable: SGTrackItem {

  /**
   If this item should be treated as a background item. A background track item is typically a stay or your home, i.e., that what you want to go back to if you don't have anything else on. Algorithms will typically hide unnecessary background items if they aren't needed.
   */
  var isBackground: Bool { get }

  /**
   Sets the actual start time on background track items - relevant if they are hiding each other.
   */
  func updateStart(_ startDate: Date)
  
  /**
   Sets the actual end time on background track items - relevant if they are hiding each other.
   */
  func updateEnd(_ endDate: Date)

}

/**
 A track item which the user can customise.
 */
@objc
public protocol SGTrackItemUserCustomizable: SGTrackItem {

  /**
   Implementing this enables resolving this location.
   
   - parameter mapAnnotation: The resolved location. Typically initiated by the user. Most likely this is a `SGKNamedCoordinate`.
   */
  func assign(_ mapAnnotation: MKAnnotation)

  #if os(iOS)
    /**
     The editing style for how to display this track item in the list.
     */
    var editingStyle: UITableViewCellEditingStyle { get }
  #endif

  /**
   Called when the user removes a "Back to X" entry before this track item, which means they want to go this item directly.
   */
  var goHereDirectly: Bool { get set }

}

/**
 A track item for which the algorithm can determine the start and end times.
 */
@objc
public protocol SGTrackItemAlgorithmOptimizable: SGTrackItem {

  /**
   Effective start and times indicate when a user can arrive/leave this event. This can be nil if the user won't make the event!
   */
  var effectiveStart: Date? { get set }
  
  var effectiveEnd: Date? { get set }

}


/**
 A kind of `SGTrackItem` that represents a trip.
 */
@objc
public protocol SGTripTrackItem : SGTrackItem {
  
  /**
   @return The trip
   */
  var trip: STKTrip! { get }
  
  /**
   The route for items that represent movement. It's an array because it can be multi-modal.
   */
  var routes: [STKDisplayableRoute] { get }
  
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
