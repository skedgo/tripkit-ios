//
//  TKUITripCell+Formatter.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 15.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

import TripKit

extension TKUITripCell {
  
  enum Formatter {
    
    static func primaryTimeString(departure: Date, arrival: Date, departureTimeZone: TimeZone, arrivalTimeZone: TimeZone, focusOnDuration: Bool, isArriveBefore: Bool, showWeekday: Bool = false) -> String {
      if focusOnDuration {
        return arrival.durationSince(departure)
      } else {
        var fullText = ""
        if showWeekday {
          fullText.append(weekdayString(departure, in: departureTimeZone))
          fullText.append(", ")
        }
        fullText.append(TKStyleManager.timeString(departure, for: departureTimeZone, relativeTo: arrivalTimeZone))
        fullText.append(" - ")
        fullText.append(TKStyleManager.timeString(arrival, for: arrivalTimeZone, relativeTo: departureTimeZone))
        return fullText
      }
    }
    
    static func secondaryTimeString(departure: Date, arrival: Date, departureTimeZone: TimeZone, arrivalTimeZone: TimeZone, focusOnDuration: Bool, isArriveBefore: Bool) -> String {
      if focusOnDuration {
        if isArriveBefore {
          let timeText = TKStyleManager.timeString(departure, for: departureTimeZone, relativeTo: arrivalTimeZone)
          return Loc.Departs(atTime: timeText)
        } else {
          let timeText = TKStyleManager.timeString(arrival, for: arrivalTimeZone, relativeTo: departureTimeZone)
          return Loc.Arrives(atTime: timeText)
        }
      } else {
        return arrival.durationSince(departure)
      }
    }
    
    static func dayOffset(of date: Date, from reference: Date, in timeZone: TimeZone) -> Int {
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = timeZone
      let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: reference), to: calendar.startOfDay(for: date)).day
      return days ?? 0
    }
    
    /// - Returns: Localised and signed number of days, e.g., "+1 day" or "-2 days", or `nil` if `offset` is 0
    static func dayOffsetString(_ offset: Int) -> String? {
      guard offset != 0 else { return nil }
      let formatter = DateComponentsFormatter()
      formatter.allowedUnits = [.day]
      formatter.unitsStyle = .full
      guard let days = formatter.string(from: DateComponents(day: abs(offset))) else { return nil }
      return (offset > 0 ? "+" : "−") + days
    }
    
    private static func weekdayString(_ date: Date, in timeZone: TimeZone) -> String {
      let formatter = DateFormatter()
      formatter.locale = .current
      formatter.timeZone = timeZone
      formatter.setLocalizedDateFormatFromTemplate("EEE")
      return formatter.string(from: date)
    }
    
    static func costString(costs: [TKTripCostType: String]) -> String {
      let displayable = displayableMetrics(for: costs)
      guard !displayable.isEmpty else { return " " }
      return displayable.joined(separator: " ⋅ ")
    }
    
    static func costAccessibilityLabel(costs: [TKTripCostType: String]) -> String {
      return displayableMetrics(for: costs)
        .map { $0.replacingOccurrences(of: "CO₂", with: "C-O-2") } // Don't say "Co subscript 2"
        .joined(separator: "; ")
    }
    
    static private func displayableMetrics(for costs: [TKTripCostType: String]) -> [String] {
      var metricValues: [String] = []
      
      for metricKey in TKUIRoutingResultsCard.config.tripMetricsToShow {
        guard let value = costs[metricKey] else { continue }
        metricValues.append(value)
      }
      
      return metricValues
    }
    
  }
  
}
