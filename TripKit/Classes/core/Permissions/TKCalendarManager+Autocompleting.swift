//
//  TKCalendarManager+Autocompleting.swift
//  TripKit
//
//  Created by Adrian Schönig on 20.04.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

extension TKCalendarManager: TKAutocompleting {
  
  enum AutocompletionError: Error {
    case unexpectedResultObject
  }
  
  public func autocomplete(_ input: String, near mapRect: MKMapRect, completion: @escaping (Result<[TKAutocompletionResult], Error>) -> Void) {
    
    let events = input.isEmpty
      ? fetchDefaultEvents()
      : fetchEvents(matching: input)
    
    let results = events.compactMap { TKCalendarManager.autocompletionResult(for: $0, search: input) }
    completion(.success(results))
  }
  
  public func annotation(for result: TKAutocompletionResult, completion: @escaping (Result<MKAnnotation, Error>) -> Void) {
    
    guard let event = result.object as? EKEvent else {
      assertionFailure("Unexpected object: \(result.object).")
      completion(.failure(AutocompletionError.unexpectedResultObject))
      return
    }
    
    let annotation = TKNamedCoordinate(event)
      ?? TKNamedCoordinate(name: nil, address: event.location)

    // make sure we keep this even if the `init(event)` didn't work.
    annotation.eventStartTime = event.startDate
    annotation.eventEndTime   = event.endDate

    // Name it after the event, not the event's location
    annotation.name = TKCalendarManager.titleString(for: event)
    annotation.sortScore = 85
    
    if annotation.coordinate.isValid {
      completion(.success(annotation))
    } else {

      let geocoder = helperGeocoder as? TKAppleGeocoder ?? TKAppleGeocoder()
      helperGeocoder = geocoder
      geocoder.geocode(annotation, near: .world) { result in
        completion(result.map { annotation })
      }
    }
  }
  
  #if os(iOS) || os(tvOS)
  @objc
  public func additionalActionTitle() -> String? {
    if isAuthorized() { return nil }
    
    return NSLocalizedString("Include events", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Button to include events in search, too.")
  }
  
  public func triggerAdditional(presenter: UIViewController, completion: @escaping (Bool) -> Void) {
    tryAuthorizationForSender(nil, in: presenter, completion: completion)
  }
  #endif
  
}


// MARK: - Helpers

extension TKCalendarManager {
  
  private func fetchDefaultEvents() -> [EKEvent] {
    let now = Date()
    guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)
      else { assertionFailure(); return [] }
    
    return fetchEventsBetweenDate(now, andEnd: tomorrow, fromCalendars:nil)
      .filter { !$0.isAllDay }
  }
 
  static func autocompletionResult(for event: EKEvent, search: String) -> TKAutocompletionResult? {
    
    guard let location = event.location, !location.isEmpty else { return nil }

    let result = TKAutocompletionResult()
    result.object = event
    result.title = TKCalendarManager.titleString(for: event)
    result.subtitle = location
    result.image = TKAutocompletionResult.image(forType: .calendar)
    
    if search.isEmpty {
      result.score = 90
      
    } else {
      
      let titleScore = TKAutocompletionResult.scoreBased(onNameMatchBetweenSearchTerm: search, candidate: result.title)
      let locationScore = TKAutocompletionResult.scoreBased(onNameMatchBetweenSearchTerm: search, candidate: result.subtitle ?? "")
      let rawScore = min(100, (titleScore + locationScore) / 2)
      result.score = Int(TKAutocompletionResult.rangedScore(forScore: UInt(rawScore), betweenMinimum: 50, andMaximum: 90))
    }
    
    return result
  }

}

extension TKNamedCoordinate {
  
  /// New named coordinate configured with the structured location
  /// information of the provided event. Returns `nil` if there's
  /// no structured location information - meaning, a location
  /// string alone is not enough.
  ///
  /// - Parameter event: Event
  @objc(initWithEvent:)
  public convenience init?(_ event: EKEvent) {
    guard let structured = event.structuredLocation, let location = structured.geoLocation else { return nil }
    
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
    get { TKParserHelper.parseDate(data["eventStartTime"]) }
    set { data["eventStartTime"] = newValue?.timeIntervalSince1970 }
  }
  
  @objc public var eventEndTime: Date? {
    get { TKParserHelper.parseDate(data["eventEndTime"]) }
    set { data["eventEndTime"] = newValue?.timeIntervalSince1970 }
  }
  
}

