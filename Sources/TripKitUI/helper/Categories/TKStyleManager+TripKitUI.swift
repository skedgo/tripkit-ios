//
//  TKStyleManager+TripKitUI.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 16/1/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKit

#if SWIFT_PACKAGE
import TripKitObjc
#endif

// MARK: - Times

extension TKStyleManager {
  
  enum CountdownMode {
    case now
    case upcoming
    case inPast
  }
  
  struct Countdown {
    let number: String
    let unit: String
    
    let durationText: String
    let accessibilityLabel: String
    let mode: CountdownMode
  }
  
  /// Determines how a countdown for a specific departure should be displayed.
  ///
  /// This is recommended to use for timetables, as it optionally allows
  /// rounding the minutes in a way that a user is less likely to get annoyed
  /// at the app as the displayed text will be overly pessimistic to get users
  /// to hurry up.
  ///
  /// - Parameters:
  ///   - minutes: Actual departure time in minutes from now
  ///   - fuzzifyMinutes: Whether the texts should be pessimistic
  /// - Returns: Structure with duration string, accessory label and mode
  static func departure(forMinutes minutes: Int, fuzzifyMinutes: Bool = true) -> Countdown {
    let absoluteMinutes = abs(minutes)
    let effectiveMinutes = fuzzifyMinutes ? fuzzifiedMinutes(minutes) : minutes
    
    func parts(components: DateComponents) -> (String, String) {
      let formatter = DateComponentsFormatter()
      
      formatter.unitsStyle = .full
      let number = formatter.string(from: components)?.trimmingCharacters(in: .letters).trimmingCharacters(in: .whitespaces) ?? ""
      
      formatter.unitsStyle = .brief
      let letter = formatter.string(from: components)?.replacingOccurrences(of: number, with: "").trimmingCharacters(in: .whitespaces) ?? ""
      
      return (number, letter)
    }
    
    let durationString: String
    let number: String
    let unit: String
    switch effectiveMinutes {
    case 0:
      durationString = Loc.Now
      number = "0"
      unit = ""
      
    case ..<60: // less than an hour
      durationString = Date.durationString(forMinutes: effectiveMinutes)
      (number, unit) = parts(components: DateComponents(minute: effectiveMinutes))
      
    case ..<1440: // less than a day
      let hours = absoluteMinutes / 60
      durationString = Date.durationString(forHours: hours)
      (number, unit) = parts(components: DateComponents(hour: hours))

    default: // days
      let days = absoluteMinutes / 1440
      durationString = Date.durationString(forDays: days)
      (number, unit) = parts(components: DateComponents(day: days))
    }
    
    let mode: CountdownMode
    let accessibilityLabel: String
    switch effectiveMinutes {
    case 0:
      mode = .now
      accessibilityLabel = Loc.Now
    case ..<0:
      mode = .inPast
      accessibilityLabel = Loc.Ago(duration: durationString)
    default:
      mode = .upcoming
      accessibilityLabel = Loc.In(duration: durationString)
    }
    
    return Countdown(
      number: number,
      unit: unit,
      durationText: durationString,
      accessibilityLabel: accessibilityLabel,
      mode: mode
    )
  }
  
  static func departureString(forMinutes minutes: Int, fuzzifyMinutes: Bool) -> String {
    return departure(forMinutes: minutes, fuzzifyMinutes: fuzzifyMinutes).durationText
  }

  static func departureAccessibilityLabel(forMinutes minutes: Int, fuzzifyMinutes: Bool) -> String {
    return departure(forMinutes: minutes, fuzzifyMinutes: fuzzifyMinutes).accessibilityLabel
  }

  static func departureIsNow(forMinutes minutes: Int, fuzzifyMinutes: Bool) -> Bool {
    return departure(forMinutes: minutes, fuzzifyMinutes: fuzzifyMinutes).mode == .now
  }
  
  private static func fuzzifiedMinutes(_ minutes: Int) -> Int {
    switch minutes {
    case ..<0:
      return minutes
    case ..<2:
      return 0
    case ..<10:
      return minutes
    case ..<20:
      return (minutes / 2) * 2
    default:
      return (minutes / 5) * 5
    }
  }
}
