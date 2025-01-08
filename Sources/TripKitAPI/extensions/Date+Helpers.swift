//
//  Date+Helpers.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 27/10/16.
//
//

import Foundation

extension Date {
  
  private static let iso8601formatter = ISO8601DateFormatter()

  public enum DateConversionError: Error {
    case invalidISO8601(String)
  }
  
  public init(iso8601: String) throws {
    if let date = Self.iso8601formatter.date(from: iso8601) {
      self = date
    } else {
      throw DateConversionError.invalidISO8601(iso8601)
    }
  }
  
  public var iso8601: String { Self.iso8601formatter.string(from: self) }
  
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
