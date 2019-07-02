//
//  OpeningHoursAPIModel.swift
//  TripKit
//
//  Created by Adrian Schoenig on 7/12/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

/// Flexible representation of opening hours
///
/// Matches OpeningHours from the tripgo-api

extension API {
  
  enum DecoderError: Error {
    case notValidTimeZoneIdentifier(String)
  }
  
  public struct OpeningHours : Codable, Equatable {
    
    /// Time zone in which the opening hours are defined
    public let timeZone: TimeZone
    fileprivate let days: [Day]
    
    private enum CodingKeys: String, CodingKey {
      case timeZone
      case days
    }

    public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      days = try values.decode([Day].self, forKey: .days)

      // Originally, we tried decoding `TimeZone.self`, but that leads
      // to a strange issue in Swift 4.0: https://bugs.swift.org/browse/SR-5981
      // If we can switch back to that, we could delete the `encode(to:)`
      // method below.
      let identifier = try values.decode(String.self, forKey: .timeZone)
      if let timeZone = TimeZone(identifier: identifier) {
        self.timeZone = timeZone
      } else {
        throw DecoderError.notValidTimeZoneIdentifier(identifier)
      }
    }
    
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(timeZone.identifier, forKey: .timeZone)
      try container.encode(days, forKey: .days)
    }

    
    /// Opening hours on a particular day of the week (with
    /// a special case for public holidays).
    public struct Day: Codable, Equatable {
      
      public let day: DayOfWeek
      public let times: [Time]
      
      private enum CodingKeys: String, CodingKey {
        case day = "name"
        case times
      }
      
      public struct Time: Codable, Equatable {
        
        public let opens: TimeInterval
        public let closes: TimeInterval

        private enum CodingKeys: String, CodingKey {
          case opens
          case closes
        }

        public init(from decoder: Decoder) throws {
          let values = try decoder.container(keyedBy: CodingKeys.self)
          opens = try Time.time(from: values, key: .opens)
          closes = try Time.time(from: values, key: .closes)
        }
        
        private static func time(from values: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) throws -> TimeInterval {
          // TimeInterval (previously parsed)
          if let interval = try? values.decode(TimeInterval.self, forKey: key) {
            return interval
          }

          // HH:MM string (from backend)
          let string: String = try values.decode(String.self, forKey: key)
          let byColon = string.components(separatedBy: ":")
          guard let leftOfColon = byColon.first, let hours = Int(leftOfColon), let rightOfColon = byColon.last else {
            throw TKOpeningHoursParserError.badTimeOfDay(string)
          }
          if let mins = Int(rightOfColon) {
            return TimeInterval(hours * 3600 + mins * 60)
          }

          // HH:MM+Xd string (from backend)
          let byPlus = rightOfColon.components(separatedBy: "+")
          if let leftOfPlus = byPlus.first, let rightOfPlus = byPlus.last?.first, let mins = Int(leftOfPlus), let days = Int(String(rightOfPlus)) {
            return TimeInterval(days * 86400 + hours * 3600 + mins * 60)
          }
          
          throw TKOpeningHoursParserError.badTimeOfDay(string)
        }
        
        
        fileprivate func isOpen(atSecondsSince12HoursToNoon seconds: TimeInterval) -> Bool {
          return opens <= seconds && seconds < closes;
        }
      }
      
      
      public enum DayOfWeek: String, Codable, Equatable {
        case monday         = "MONDAY"
        case tuesday        = "TUESDAY"
        case wednesday      = "WEDNESDAY"
        case thursday       = "THURSDAY"
        case friday         = "FRIDAY"
        case saturday       = "SATURDAY"
        case sunday         = "SUNDAY"
        case publicHoliday  = "PUBLIC_HOLIDAY"
        
        public static let weekdays: [DayOfWeek] = [
          .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
        ]
        
        public var localizedString: String {
          if let weekday = weekday {
            return TKCustomEventRecurrenceRule.longString(forWeekday: weekday)
          } else {
            return Loc.PublicHoliday
          }
        }
        
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
      
    }
  }
}

fileprivate enum TKOpeningHoursParserError: Error {
  case badTimeOfDay(String)
}

extension API.OpeningHours {
  
  /// Checks if opening hour specify that the provided that is open.
  ///
  /// - warning: This does not cover public holidays. If `date`
  ///     is on a public holiday, the day of the week will be used.
  ///
  /// - Parameter date: Date to check
  /// - Returns: Whether open on provided date
  public func isOpen(at date: Date) -> Bool {
    for day in days {
      if day.isOpen(at:date, in: timeZone) {
        return true
      }
    }
    return false
  }
  
  /// Sorted days relative to provided first-day-of-week
  ///
  /// - Parameter starting: First day of the week
  /// - Returns: Sorted days
  public func days(starting: WeekdayIndex = .monday) -> [Day] {
    var allDays = days
    for day in Day.DayOfWeek.weekdays {
      if !allDays.contains(where: { $0.day == day }) {
        allDays.append(Day(day: day, times: []))
      }
    }
    
    return allDays.sorted { firstDay, secondDay in
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

extension API.OpeningHours.Day {
  
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
  
  
  /// Checks if opening hour specify that the provided that is open.
  ///
  /// - warning: This does not cover public holidays. If `date`
  ///     is on a public holiday, the day of the week will be used.
  ///
  /// - Parameter date: Date to check
  /// - Returns: Whether open on provided date
  public func isOpen(at date: Date, in timeZone: TimeZone) -> Bool {
    let seconds = date.timeIntervalSince(date.midnight(in: timeZone))
    for time in times {
      if time.isOpen(atSecondsSince12HoursToNoon: seconds) {
        return true
      }
    }
    return false
  }
  
}
