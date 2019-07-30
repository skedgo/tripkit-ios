//
//  DepartureCard+Content.swift
//  TripGoAppKit
//
//  Created by Kuan Lun Huang on 28/3/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

public struct TKUIDepartureCardContentModel {
  
  public var servicePlaceholderImage: UIImage?
  public var serviceImageURL: URL?
  public var serviceImageIsTemplate = false
  public var serviceLineColor: UIColor?
  public var serviceImageIsColorCoded: Bool = false
  public var title: NSAttributedString
  public var subtitle: String?
  public var subsubtitle: String?
  public var approximateTimeToDepart: Date?
  public var serviceIsCancelled = false
  public var serviceIsAccessible: Bool?
  public var requiresAccessibilitySupport = false
  public var serviceAlerts: [Alert] = []
  public var serviceOccupancies: Observable<[[API.VehicleOccupancy]]>?
  
  public init(title: NSAttributedString) {
    self.title = title
  }
  
}

extension TKUIDepartureCellContent {
  
  static func build(for visit: StopVisits) -> TKUIDepartureCellContent? {
    guard let service = (visit.service as Service?) else {
      return nil
    }
    
    let accessibility: TKUIAccessibilityDisplaySetting
    if TKUserProfileHelper.showWheelchairInformation {
      let serviceIsAccessible: Bool?
      if let isStopAccessible = visit.stop.isWheelchairAccessible {
        serviceIsAccessible = isStopAccessible && service.isWheelchairAccessible
      } else if service.isWheelchairAccessible {
        serviceIsAccessible = true
      } else {
        serviceIsAccessible = nil
      }
      accessibility = .enabled(serviceIsAccessible)
    } else {
      accessibility = .disabled
    }
    
    let occupancies = service.vehicle?.rx.components
      .map { $0.map { $0.map { $0.occupancy ?? .unknown } } }
    
    return TKUIDepartureCellContent(
      placeHolderImage: service.modeImage(for: .listMainMode),
      imageURL: service.modeImageURL(for: .listMainMode),
      imageIsTemplate: service.modeImageIsTemplate,
      imageTintColor: nil,
      serviceShortName: service.shortIdentifier(),
      serviceColor: service.color as? UIColor,
      serviceIsCancelled: service.isCancelled,
      title: visit.buildTitle(),
      subtitle: visit.secondaryInformation(),
      approximateTimeToDepart: visit.countdownDate(),
      accessibilityDisplaySetting: accessibility,
      alerts: service.allAlerts(),
      vehicleOccupancies: occupancies
    )
    
//    model.serviceImageIsColorCoded = TKUIDeparturesCard.config.colorCodeTransitIcons
//    model.subsubtitle = visit.realTimeInformation(true)
  }
  
}

// MARK: -
extension StopVisits {
  
  fileprivate func buildTitle() -> NSAttributedString {
    var title = realTimeInformation(false) + " · "
    
    // Frequency based service
    switch timing {
    case .frequencyBased(let frequency, _, _, _):
      let freqString = Date.durationString(forMinutes: Int(frequency / 60))
      title += Loc.Every(repetition: freqString)
      
    case .timetabled(let arrival, let departure):
      let timeZone = stop.region?.timeZone
      
      var departureString = ""
      if let departureDate = departure {
        departureString = TKStyleManager.timeString(departureDate, for: timeZone)
      }
      
      if self is DLSEntry {
        // time-table
        if !departureString.isEmpty {
          title += departureString
        }
        
        var arrivalString = ""
        if let arrivalDate = arrival {
          arrivalString = TKStyleManager.timeString(arrivalDate, for: timeZone)
        }
        
        if !arrivalString.isEmpty {
          title += String(format: " - %@", arrivalString)
        }
        
      } else if !departureString.isEmpty {
        title += departureString
      }
    }
    
    return NSAttributedString(string: title)
  }
  
}
