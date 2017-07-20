//
//  Date+Helpers.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 27/10/16.
//
//

import Foundation

extension Date {
  
  public func midnight(in timeZone: TimeZone) -> Date {
    var calendar = Calendar.autoupdatingCurrent
    calendar.timeZone = timeZone
    return calendar.startOfDay(for: self)
  }
  
  public func nextMidnight(in timeZone: TimeZone) -> Date {
    var calendar = Calendar.autoupdatingCurrent
    calendar.timeZone = timeZone
    let midnight = self.midnight(in: timeZone)
    return calendar.date(byAdding: .day, value: 1, to: midnight)!
  }
  
}
