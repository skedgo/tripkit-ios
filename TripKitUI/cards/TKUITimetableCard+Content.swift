//
//  TKUITimetableCard+Content.swift
//  TripKitUI
//
//  Created by Kuan Lun Huang on 28/3/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

extension TKUIDepartureCellContent {
  
  static func build(for visit: StopVisits) -> TKUIDepartureCellContent? {
    guard let service = (visit.service as Service?) else {
      return nil
    }
    
    let accessibility: TKUIWheelchairAccessibility
    if let isStopAccessible = visit.stop.isWheelchairAccessible {
      accessibility = isStopAccessible && service.isWheelchairAccessible
        ? .accessible
        : .notAccessible
    } else if service.isWheelchairAccessible {
      accessibility = .accessible
    } else {
      accessibility = .unknown
    }
    
    let serviceColor = service.color as? UIColor
    return TKUIDepartureCellContent(
      placeholderImage: service.modeImage(for: .listMainMode),
      imageURL: service.modeImageURL(for: .listMainMode),
      imageIsTemplate: service.modeImageIsTemplate,
      imageTintColor: TKUITimetableCard.config.colorCodeTransitIcons ? serviceColor : nil,
      modeName: service.modeTitle ?? "",
      serviceShortName: service.shortIdentifier(),
      serviceColor: serviceColor,
      serviceIsCancelled: service.isCancelled,
      timeText: visit.buildTimeText(),
      lineText: visit.buildLineText(),
      approximateTimeToDepart: visit.countdownDate(),
      alwaysShowAccessibilityInformation: TKUserProfileHelper.showWheelchairInformation,
      wheelchairAccessibility: accessibility,
      alerts: service.allAlerts(),
      vehicleOccupancies: service.vehicle?.rx.occupancies
    )
  }
  
}

// MARK: -
extension StopVisits {
  
  fileprivate func buildTimeText() -> NSAttributedString {
    var text = realTimeInformation(false) + " · "
    
    // Frequency based service
    switch timing {
    case .frequencyBased(let frequency, let start, let end, _):
      let freqString = Date.durationString(forMinutes: Int(frequency / 60))
      text += Loc.Every(repetition: freqString)
      
      if let start = start, let end = end {
        let timeZone = stop.region?.timeZone ?? .current
        text += " ⋅ "
        text += TKStyleManager.timeString(start, for: timeZone)
        text += " - "
        text += TKStyleManager.timeString(end, for: timeZone)
      }

      
    case .timetabled(let arrival, let departure):
      let timeZone = stop.region?.timeZone
      
      var departureString = ""
      if let departureDate = departure {
        departureString = TKStyleManager.timeString(departureDate, for: timeZone)
      }
      
      if self is DLSEntry {
        // time-table
        if !departureString.isEmpty {
          text += departureString
        }
        
        var arrivalString = ""
        if let arrivalDate = arrival {
          arrivalString = TKStyleManager.timeString(arrivalDate, for: timeZone)
        }
        
        if !arrivalString.isEmpty {
          text += String(format: " - %@", arrivalString)
        }
        
      } else if !departureString.isEmpty {
        text += departureString
      }
    }
    
    let color = realTimeStatus().color
    return NSAttributedString(string: text, attributes: [.foregroundColor: color])
  }
  
  fileprivate func buildLineText() -> String? {
    var text = ""
    
    // platforms
    if let standName = stop.shortName?.trimmingCharacters(in: .whitespaces), !standName.isEmpty {
      if !text.isEmpty {
        text += " ⋅ "
      }
      text += standName
    }
    
    // direction
    if let direction = service.direction?.trimmingCharacters(in: .whitespaces), !direction.isEmpty {
      if !text.isEmpty {
        text += " ⋅ "
      }
      text += direction
    }
    
    return text.isEmpty ? nil : text
  }
  
}
