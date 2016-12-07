//
//  TKOpeningHours.swift
//  TripKit
//
//  Created by Adrian Schoenig on 7/12/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import Marshal


/// Flexible representation of opening hours
public struct TKOpeningHours : Unmarshaling {
  
  /// Time zone in which the opening hours are defined
  public let timeZone: TimeZone
  
  fileprivate let days: [Day]
  
  
  /// Opening hours on a particular day of the week (with
  /// a special case for public holidays).
  public struct Day: Unmarshaling {
    
    public let day: DayOfWeek
    public let times: [Time]
    
    
    public struct Time: Unmarshaling {
      
      fileprivate let opens: TimeInterval
      fileprivate let closes: TimeInterval
      
      
      public init(object: MarshaledObject) throws {
        opens   = try Time.time(from: object, key: "opens")
        closes  = try Time.time(from: object, key: "closes")
      }
      
      
      fileprivate static func time(from object: MarshaledObject, key: String) throws -> TimeInterval {
        let string: String = try object.value(for: key)
        let split = string.components(separatedBy: ":")
        guard
          let first = split.first,
          let hours = Int(first),
          let last  = split.last,
          let mins  = Int(last)
          else {
            throw TKOpeningHoursParserError.badTimeOfDay(string)
        }
        
        return TimeInterval(hours * 3600 + mins * 60)
      }
      
      
      fileprivate func isOpen(atSecondsSince12HoursToNoon seconds: TimeInterval) -> Bool {
        return opens <= seconds && seconds < closes;
      }
    }
    
    
    public enum DayOfWeek: String {
      case monday         = "MONDAY"
      case tuesday        = "TUESDAY"
      case wednesday      = "WEDNESDAY"
      case thursday       = "THURSDAY"
      case friday         = "FRIDAY"
      case saturday       = "SATURDAY"
      case sunday         = "SUNDAY"
      case publicHoliday  = "PUBLIC_HOLIDAY"
      
      
      /// Integer matching `NSDateComponents.weekday` or
      /// `nil` in case of public holiday.
      fileprivate var weekday: Int? {
        switch self {
        case .sunday:         return 1
        case .monday:         return 2
        case .tuesday:        return 3
        case .wednesday:      return 4
        case .thursday:       return 5
        case .friday:         return 6
        case .saturday:       return 7
        case .publicHoliday:  return nil
        }
      }
      
      
      fileprivate func relativeWeekday(to starting: WeekdayIndex) -> Int? {
        guard let weekday = self.weekday else { return nil }
        if weekday < starting.rawValue {
          return weekday + 7
        } else {
          return weekday
        }
      }
    }
    
    
    public init(object: MarshaledObject) throws {
      day   = try object.value(for: "name")
      times = try object.value(for: "times")
    }
    
    
    /// Checks if provided date is covered by this particular day
    ///
    /// - warning: This does not cover public holidays. If this
    ///     object represents a public holiday, the return value
    ///     is always `false`.
    ///
    /// - Parameters:
    ///   - date: Date to check
    ///   - timeZone: Time zone of the date object
    /// - Returns: If date is covered by this particular day.
    public func contains(_ date: Date, in timeZone: TimeZone) -> Bool {
      var gregorian = Calendar(identifier: .gregorian)
      gregorian.timeZone = timeZone
      let weekday = gregorian.component(.weekday, from: date)
      return weekday == day.weekday
    }
    
  }
  
  
  public init(object: MarshaledObject) throws {
    timeZone = try object.value(for: "timeZone")
    days     = try object.value(for: "days")
  }
  
  
  /// Checks if opening hour specify that the provided that is open.
  ///
  /// - warning: This does not cover public holidays. If `date`
  ///     is on a public holiday, the day of the week will be used.
  ///
  /// - Parameter date: Date to check
  /// - Returns: Whether open on provided date
  public func isOpen(at date: Date) -> Bool {
    for day in days {
      if day.contains(date, in: timeZone) {
        let seconds = date.timeIntervalSince(date.midnight(in: timeZone))
        for time in day.times {
          if time.isOpen(atSecondsSince12HoursToNoon: seconds) {
            return true
          }
        }
        return false
      }
    }
    return false
  }
  
  
  /// Sorted days relative to provided first-day-of-week
  ///
  /// - Parameter starting: First day of the week
  /// - Returns: Sorted days
  public func days(starting: WeekdayIndex = .monday) -> [Day] {
    return days.sorted { firstDay, secondDay in
      guard let first = firstDay.day.relativeWeekday(to: starting) else {
        return false
      }
      guard let second = secondDay.day.relativeWeekday(to: starting) else {
        return true
      }
      return first < second
    }
  }
  
}

fileprivate enum TKOpeningHoursParserError: Error {
  case badTimeZoneIdentifier(String)
  case badTimeOfDay(String)
}

extension TimeZone: ValueType {
  public static func value(from object: Any) throws -> TimeZone {
    guard let identifier = object as? String else {
      throw MarshalError.typeMismatch(expected: String.self, actual: type(of: object))
    }
    guard let timeZone = TimeZone(identifier: identifier) else {
      throw TKOpeningHoursParserError.badTimeZoneIdentifier(identifier)
    }
    return timeZone
  }
}

