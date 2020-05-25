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
  
  static func build(embarkation: StopVisits, disembarkation: StopVisits? = nil) -> TKUIDepartureCellContent? {
    guard let service = (embarkation.service as Service?) else {
      return nil
    }

    // Note, for DLS entries `disembarkation` will be nil, but the accessibility
    // is already handled then under `disembarkation`.
    var accessibility = embarkation.wheelchairAccessibility
    if let atEnd = disembarkation?.wheelchairAccessibility {
      accessibility = accessibility.combine(with: atEnd)
    }
    
    let serviceColor = service.color
    return TKUIDepartureCellContent(
      placeholderImage: service.modeImage(for: .listMainMode),
      imageURL: service.modeImageURL(for: .listMainMode),
      imageIsTemplate: service.modeImageIsTemplate,
      imageTintColor: TKUICustomization.shared.colorCodeTransitIcons ? serviceColor : nil,
      modeName: service.modeTitle ?? "",
      serviceShortName: service.shortIdentifier(),
      serviceColor: serviceColor,
      serviceIsCanceled: service.isCanceled,
      accessibilityLabel: embarkation.accessibilityDescription(includeRealTime: true),
      accessibilityTimeText: embarkation.buildTimeText(spacer: ";").string,
      timeText: embarkation.buildTimeText(),
      lineText: embarkation.buildLineText(),
      approximateTimeToDepart: embarkation.countdownDate,
      wheelchairAccessibility: accessibility,
      alerts: service.allAlerts(),
      vehicleComponents: service.vehicle?.rx.components
    )
  }
  
}

// MARK: -
extension StopVisits {
  
  fileprivate func buildTimeText(spacer: String = "·") -> NSAttributedString {
    var text = realTimeInformation(false) + " \(spacer) "
    
    // Frequency based service
    switch timing {
    case .frequencyBased(let frequency, let start, let end, _):
      let freqString = Date.durationString(forMinutes: Int(frequency / 60))
      text += Loc.Every(repetition: freqString)
      
      if let start = start, let end = end {
        let timeZone = stop.region?.timeZone ?? .current
        text += " \(spacer) "
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
    
    let color = realTimeStatus.color
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
