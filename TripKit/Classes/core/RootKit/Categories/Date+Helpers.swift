//
//  Date+Helpers.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 27/10/16.
//
//

import Foundation

@available(iOS 10, *)
extension Date {
  
  fileprivate static let iso8601formatter = ISO8601DateFormatter()

  fileprivate static func nativelyFromISO8601(_ iso8601: String) -> Date? {
    return iso8601formatter.date(from: iso8601)
  }
  
  fileprivate func iso8601Natively() -> String {
    return Date.iso8601formatter.string(from: self)
  }
  
}

extension Date {
  
  public enum DateConversionError: Error {
    case invalidISO8601(String)
  }
  
  public init(iso8601: String) throws {
    if #available(iOS 10, *), let date = Date.nativelyFromISO8601(iso8601) {
      self = date
    } else if let date = NSDate(fromISO8601String: iso8601) {
      self = date as Date
    } else {
      throw DateConversionError.invalidISO8601(iso8601)
    }
  }
  
  public var iso8601: String {
    if #available(iOS 10, *) {
      return iso8601Natively()
    } else {
      return (self as NSDate).iso8601String()
    }
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
