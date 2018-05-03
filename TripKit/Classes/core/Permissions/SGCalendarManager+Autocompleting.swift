//
//  SGCalendarManager+Autocompleting.swift
//  TripKit
//
//  Created by Adrian Schönig on 20.04.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

extension SGCalendarManager: SGAutocompletionDataProvider {
  
  public func autocompleteFast(_ string: String, for mapRect: MKMapRect) -> [SGAutocompletionResult] {
    let events = string.isEmpty ? fetchDefaultEvents() : fetchEvents(matching: string)
    return SGCalendarManager.autocompletionResults(for: events, search: string)
  }
  
  public func annotation(for result: SGAutocompletionResult) -> MKAnnotation? {
    guard let event = result.object as? EKEvent else {
      assertionFailure("Unexpected object: \(result.object).")
      return nil
    }
    
    let annotation = SGKNamedCoordinate(event)
      ?? SGKNamedCoordinate(name: nil, address: event.location)

    // make sure we keep this even if the `init(event)` didn't work.
    annotation.eventStartTime = event.startDate
    annotation.eventEndTime   = event.endDate

    // Name it after the event, not the event's location
    annotation.name = SGCalendarManager.titleString(for: event)
    annotation.sortScore = 85
    return annotation
  }
  
  #if os(iOS) || os(tvOS)
  public func additionalActionString() -> String? {
    return isAuthorized() ? nil : NSLocalizedString("Include events", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Button to include events in search, too.")
  }
  
  public func additionalAction(forPresenter presenter: UIViewController, completion actionBlock: @escaping SGAutocompletionDataActionBlock) {
    tryAuthorizationForSender(nil, in: presenter) { enabled in
      actionBlock(enabled)
    }
  }
  #endif

}

extension SGKNamedCoordinate {
  
  /// New named coordinate configured with the structured location
  /// information of the provided event. Returns `nil` if there's
  /// no structured location information - meaning, a location
  /// string alone is not enough.
  ///
  /// - Parameter event: Event
  @objc(initWithEvent:)
  public convenience init?(_ event: EKEvent) {
    guard #available(iOS 9.0, *), let structured = event.structuredLocation, let location = structured.geoLocation else { return nil }
    
    let address: String?
    if let fromStructure = structured.value(forKey: "address") as? String {
      address = fromStructure
    } else {
      address = event.location
    }
    
    self.init(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, name: structured.title, address: address)
    
    eventStartTime = event.startDate
    eventEndTime = event.endDate
  }
  
  @objc public var eventStartTime: Date? {
    get {
      guard let interval = data["eventStartTime"] as? TimeInterval else { return nil }
      return Date(timeIntervalSince1970: interval)
    }
    set {
      data["eventStartTime"] = newValue?.timeIntervalSince1970
    }
  }
  
  @objc public var eventEndTime: Date? {
    get {
      guard let interval = data["eventEndTime"] as? TimeInterval else { return nil }
      return Date(timeIntervalSince1970: interval)
    }
    set {
      data["eventEndTime"] = newValue?.timeIntervalSince1970
    }
  }
  
}

