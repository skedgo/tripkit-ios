//
//  TKCalendarManager.swift
//  TripKit
//
//  Created by Adrian Schoenig on 20/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension TKCalendarManager {
  
  public static let shared = TKCalendarManager.__sharedInstance()
  
}

// MARK: - Autocompletion

extension TKCalendarManager {
  
  @objc
  public func fetchDefaultEvents() -> [EKEvent] {
    let now = Date()
    guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)
      else { assertionFailure(); return [] }
    
    return fetchEventsBetweenDate(now, andEnd: tomorrow, fromCalendars:nil)
      .filter { !$0.isAllDay }
  }
  
  @objc(autocompletionResultsForEvents:searchTerm:)
  static func autocompletionResults(for events: [EKEvent], search: String) -> [TKAutocompletionResult] {
    
    return events.compactMap { event in
      guard let location = event.location, !location.isEmpty else { return nil }
      return autocompletionResult(for: event, search: search)
    }
  }
  
  @objc(autocompletionResultForEvent:searchTerm:)
  static func autocompletionResult(for event: EKEvent, search: String) -> TKAutocompletionResult {
    let result = TKAutocompletionResult()
    result.object = event
    result.title = TKCalendarManager.titleString(for: event)
    result.subtitle = event.location
    result.image = TKAutocompletionResult.image(forType: .calendar)
    
    if search.isEmpty {
      result.score = 90 // TODO: Add
    } else {
      
      let titleScore = TKAutocompletionResult.scoreBased(onNameMatchBetweenSearchTerm: search, candidate: result.title)
      let locationScore = TKAutocompletionResult.scoreBased(onNameMatchBetweenSearchTerm: search, candidate: result.subtitle ?? "")
      let rawScore = min(100, (titleScore + locationScore) / 2)
      result.score = Int(TKAutocompletionResult.rangedScore(forScore: UInt(rawScore), betweenMinimum: 50, andMaximum: 90))
    }
    
    return result
  }
  
}
