//
//  SGTrackHelper.swift
//  TripKit
//
//  Created by Adrian Schoenig on 21/7/17.
//
//

import Foundation

extension SGTrackHelper {
  
  @objc
  public static func trackItemIsTrip(_ trackItem: SGTrackItem) -> Bool {
    return trackItem is SGTripTrackItem
  }
  
  @objc(originOfTrackItem:)
  public static func origin(of trackItem: SGTrackItem) -> MKAnnotation? {
    if let trip = trackItem as? SGTripTrackItem {
      return trip.routeStart
    } else {
      return trackItem.mapAnnotation
    }
  }

  @objc(destinationOfTrackItem:)
  public static func destination(of trackItem: SGTrackItem) -> MKAnnotation? {
    if let trip = trackItem as? SGTripTrackItem {
      return trip.routeEnd
    } else {
      return trackItem.mapAnnotation
    }
  }
  
  
}
