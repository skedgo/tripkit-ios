//
//  SGCalendarManager.swift
//  TripKit
//
//  Created by Adrian Schoenig on 20/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension SGCalendarManager {
  
  public static let shared = SGCalendarManager.__sharedInstance()
  
}

// MARK: - Autocompletion

extension SGCalendarManager {
  
  @objc
  public func fetchDefaultEvents() -> [EKEvent] {
    let now = Date()
    guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)
      else { assertionFailure(); return [] }
    
    return fetchEventsBetweenDate(now, andEnd: tomorrow, fromCalendars:nil)
      .filter { !$0.isAllDay }
  }
  
  @objc(autocompletionResultsForEvents:searchTerm:)
  static func autocompletionResults(for events: [EKEvent], search: String) -> [SGAutocompletionResult] {
    
    return events.compactMap { event in
      guard let location = event.location, !location.isEmpty else { return nil }
      return autocompletionResult(for: event, search: search)
    }
  }
  
  @objc(autocompletionResultForEvent:searchTerm:)
  static func autocompletionResult(for event: EKEvent, search: String) -> SGAutocompletionResult {
    let result = SGAutocompletionResult()
    result.object = event
    result.title = SGCalendarManager.titleString(for: event)
    result.subtitle = event.location
    result.image = SGAutocompletionResult.image(forType: .calendar)
    
    if search.isEmpty {
      result.score = 90 // TODO: Add
    } else {
      
      let titleScore = SGAutocompletionResult.scoreBased(onNameMatchBetweenSearchTerm: search, candidate: result.title)
      let locationScore = SGAutocompletionResult.scoreBased(onNameMatchBetweenSearchTerm: search, candidate: result.subtitle ?? "")
      let rawScore = min(100, (titleScore + locationScore) / 2)
      result.score = Int(SGAutocompletionResult.rangedScore(forScore: UInt(rawScore), betweenMinimum: 50, andMaximum: 90))
    }
    
    return result
  }
  
}
