//
//  SGCustomEventRecurrenceRule.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 18/09/2016.
//  Copyright © 2016 SkedGo. All rights reserved.

import Foundation

extension SGCustomEventRecurrenceRule {
  
  /// Enumates the specified recurrence rules for the provided date range,
  /// calling the handler for each recurrence with the start and end date.
  ///
  /// - parameter rule: String for the recurrence rule as used by this class
  /// - parameter startTime: Start time in seconds since 12 hours before noon
  /// - parameter duration: Duration in seconds
  /// - parameter earliest: Earliest date that any recurrence can end
  /// - parameter latest: Latest date that any recurrence can start
  /// - parameter timeZone: The time zone for which to enumarete the recurrences
  /// - parameter handler: Block call on same thread for every recurrence, providing both start date and end date of each recurrence.
  public class func enumerateRecurrences(
    ofRule rule: String, startTime: TimeInterval, duration: TimeInterval,
    earliest: Date, latest: Date, for timeZone: TimeZone,
    handler: (_ start: Date, _ end: Date) -> Void)
  {
    assert(startTime >= 0)
    assert(duration >= 0)
    
    var gregorian = Calendar(identifier: .gregorian)
    gregorian.timeZone = timeZone
    
    var components = gregorian.dateComponents(in: timeZone, from: earliest)
    components.hour = 0
    components.minute = 0
    components.second = Int(startTime)

    while true {
      let applies: Bool
      guard let start = gregorian.date(from: components) else {
        preconditionFailure()
      }
      
      if rule.characters.first == "W" {
        let weekday = gregorian.component(.weekday, from: start)
        
        // 1 == sunday, 7 == saturday
        let index = rule.characters.index(rule.characters.startIndex, offsetBy: weekday)
        applies = (rule.characters[index] == "1")
        
      } else {
        assertionFailure("Unexpected recurrence: \(rule)")
        applies = false
      }
      
      let end = start.addingTimeInterval(duration)
      if applies && end.timeIntervalSince(earliest) >= 0 {
        if start.timeIntervalSince(latest) > 0 {
          break
        }
        handler(start, end)
      }
      
      components.day = components.day! + 1
    }
  }
  
}
