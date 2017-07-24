//
//  Date+Helpers.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 27/10/16.
//
//

import Foundation

extension Date {
  
  public enum DateConversionError: Error {
    case invalidISO8601(String)
  }
  
  public init(iso8601: String) throws {
    guard let date = NSDate(fromISO8601String: iso8601) else {
      throw DateConversionError.invalidISO8601(iso8601)
    }
    self = date as Date
  }
  
  public var iso8601: String {
    return (self as NSDate).iso8601String()
  }
  
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
