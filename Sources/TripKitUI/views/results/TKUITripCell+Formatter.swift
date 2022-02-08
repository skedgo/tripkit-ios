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
  
  class Formatter: NSObject {
    var primaryFont: UIFont?
    var primaryColor: UIColor = .tkLabelPrimary
    
    var secondaryFont: UIFont?
    var secondaryColor: UIColor = .tkLabelSecondary
    
    var costColor: UIColor = .tkLabelSecondary
    
    override init() {
      super.init()
    }
    
    func primaryTimeString(departure: Date, arrival: Date, departureTimeZone: TimeZone, arrivalTimeZone: TimeZone, focusOnDuration: Bool, isArriveBefore: Bool) -> NSAttributedString {
      let attributes = [
        NSAttributedString.Key.font: TKStyleManager.customFont(forTextStyle: .body),
        NSAttributedString.Key.foregroundColor: UIColor.tkLabelPrimary
      ]
      
      if focusOnDuration {
        return NSAttributedString(string: arrival.durationSince(departure), attributes: attributes)
      } else {
        var fullText = TKStyleManager.timeString(departure, for: departureTimeZone, relativeTo: arrivalTimeZone)
        fullText.append(" - ")
        fullText.append(TKStyleManager.timeString(arrival, for: arrivalTimeZone, relativeTo: departureTimeZone))
        return NSAttributedString(string: fullText, attributes: attributes)
      }
    }
    
    func secondaryTimeString(departure: Date, arrival: Date, departureTimeZone: TimeZone, arrivalTimeZone: TimeZone, focusOnDuration: Bool, isArriveBefore: Bool) -> NSAttributedString {
      let attributes = [
          NSAttributedString.Key.font: TKStyleManager.customFont(forTextStyle: .subheadline),
          NSAttributedString.Key.foregroundColor: UIColor.tkLabelSecondary
      ]
      
      if focusOnDuration {
        if isArriveBefore {
          let timeText = TKStyleManager.timeString(departure, for: departureTimeZone, relativeTo: arrivalTimeZone)
          let fullText = "\(Loc.Departs(atTime: timeText))"
          return NSAttributedString(string: fullText, attributes: attributes)
        } else {
          let timeText = TKStyleManager.timeString(arrival, for: arrivalTimeZone, relativeTo: departureTimeZone)
          let fullText = "\(Loc.Arrives(atTime: timeText))"
          return NSAttributedString(string: fullText, attributes: attributes)
        }
      } else {
        return NSAttributedString(string: arrival.durationSince(departure), attributes: attributes)
      }
    }
    
    func costString(costs: [TKTripCostType: String]) -> NSAttributedString {
      let displayable = displayableMetrics(for: costs)
      guard !displayable.isEmpty else { return NSAttributedString(string: " ") }
      let joint = displayable.joined(separator: " ⋅ ")
      return NSAttributedString(string: joint, attributes: [.foregroundColor: costColor])
    }
    
    func costAccessibilityLabel(costs: [TKTripCostType: String]) -> String {
      return displayableMetrics(for: costs)
        .map { $0.replacingOccurrences(of: "CO₂", with: "C-O-2") }
        .joined(separator: "; ")
    }
    
    private func displayableMetrics(for costs: [TKTripCostType: String]) -> [String] {
      var metricValues: [String] = []
      
      for metricKey in TKUIRoutingResultsCard.config.tripMetricsToShow {
        guard let value = costs[metricKey] else { continue }
        metricValues.append(value)
      }
      
      return metricValues
    }
    
  }
  
}
