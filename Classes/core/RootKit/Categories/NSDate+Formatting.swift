//
//  NSDate+Formatting.swift
//  TripGo
//
//  Created by Adrian Schoenig on 19/02/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension Date {
  /**
  - returns: '1 hour, 10 minutes'
  */
  public static func durationStringLong(forMinutes minutes: Int) -> String {
    return durationString(minutes: minutes, unitsStyle: .full)
  }
  
  /**
   - returns: '1hr 10min'
   */
  public static func durationStringMedium(forMinutes minutes: Int) -> String {
    return durationString(minutes: minutes, unitsStyle: .short)
  }

  /**
   - returns: '1day'
   */
  public static func durationString(forDays days: Int) -> String {
    return durationString(days: days, unitsStyle: .abbreviated)
  }

  /**
   - returns: '1h'
   */
  public static func durationString(forHours hours: Int) -> String {
    return durationString(hours: hours, unitsStyle: .abbreviated)
  }

  /**
   - returns: '1h 10m'
   */
  public static func durationString(forMinutes minutes: Int) -> String {
    return durationString(minutes: minutes, unitsStyle: .abbreviated)
  }

  /**
   - returns: '60s'
   */
  public static func durationString(forSeconds seconds: TimeInterval) -> String {
    return durationString(seconds: seconds, unitsStyle: .abbreviated)
  }

  /**
   - returns: '1:10'
   */
  public static func durationStringShort(forMinutes minutes: Int) -> String {
    return durationString(minutes: minutes, unitsStyle: .positional)
  }

  private static func durationString(days: Int? = nil, hours: Int? = nil, minutes: Int? = nil, seconds: TimeInterval? = nil, unitsStyle: DateComponentsFormatter.UnitsStyle) -> String {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = unitsStyle
    
    var components = DateComponents()
    if let days = days {
      components.day = days
    } else if let hours = hours {
      components.hour = hours
    } else if let minutes = minutes {
      if minutes > 59 {
        components.hour = minutes / 60
      }
      components.minute = minutes % 60
    } else if let seconds = seconds {
      components.second = Int(seconds)
    }
    
    return formatter.string(from: components)!
  }
  
  public func minutesSince(_ other: Date) -> Int {
    let rounded = round(timeIntervalSince(other) / 60)
    return Int(rounded)
  }
  
  public func durationSince(_ other: Date) -> String {
    let minutes = minutesSince(other)
    if minutes < 1 {
      return ""
    }
    return Date.durationStringMedium(forMinutes:minutes)
  }

  public func durationShortSince(_ other: Date) -> String {
    let minutes = minutesSince(other)
    if minutes < 1 {
      return ""
    }
    return Date.durationStringShort(forMinutes: minutes)
  }

  public func durationLongSince(_ other: Date) -> String {
    let minutes = minutesSince(other)
    if minutes < 1 {
      return ""
    }
    return Date.durationStringLong(forMinutes: minutes)
  }

}
