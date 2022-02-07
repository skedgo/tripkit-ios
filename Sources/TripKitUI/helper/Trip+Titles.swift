//
//  Trip+Titles.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 04.09.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKit

extension Trip {
  
  func timeTitles(capitalize: Bool) -> (title: String, subtitle: String)? {
    guard let departureTime = departureTime, let arrivalTime = arrivalTime else {
      return nil // This can happen during KVO
    }
    
    return Self.timeTitles(
      departure: departureTime,
      arrival: arrivalTime,
      departureTimeZone: departureTimeZone,
      arrivalTimeZone: arrivalTimeZone ?? departureTimeZone,
      focusOnDuration: !departureTimeIsFixed,
      hideExactTimes: hideExactTimes,
      isArriveBefore: request.type == .arriveBefore,
      capitalize: true
    )
  }
  
  static func timeTitles(departure: Date, arrival: Date, departureTimeZone: TimeZone, arrivalTimeZone: TimeZone, focusOnDuration: Bool, hideExactTimes: Bool, isArriveBefore: Bool, capitalize: Bool = false) -> (title: String, subtitle: String) {
    
    guard !hideExactTimes else { return ("", "") }

    let duration = arrival.durationSince(departure)
    if focusOnDuration {
      let subtitle: String
      if isArriveBefore {
        let timeText = TKStyleManager.timeString(departure, for: departureTimeZone, relativeTo: arrivalTimeZone)
        subtitle = Loc.Departs(atTime: timeText, capitalize: capitalize)
      } else {
        let timeText = TKStyleManager.timeString(arrival, for: arrivalTimeZone, relativeTo: departureTimeZone)
        subtitle = Loc.Arrives(atTime: timeText, capitalize: capitalize)
      }
      
      return (duration, subtitle)
    
    } else {
      var title = TKStyleManager.timeString(departure, for: departureTimeZone, relativeTo: arrivalTimeZone)
      title += " - "
      title += TKStyleManager.timeString(arrival, for: arrivalTimeZone, relativeTo: departureTimeZone)
      
      return (title, duration)
    }
  }

}
