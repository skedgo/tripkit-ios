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
    
    static func primaryTimeString(departure: Date, arrival: Date, departureTimeZone: TimeZone, arrivalTimeZone: TimeZone, focusOnDuration: Bool, isArriveBefore: Bool) -> String {
      if focusOnDuration {
        return arrival.durationSince(departure)
      } else {
        var fullText = TKStyleManager.timeString(departure, for: departureTimeZone, relativeTo: arrivalTimeZone)
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
