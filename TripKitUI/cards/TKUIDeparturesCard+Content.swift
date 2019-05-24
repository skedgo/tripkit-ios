//
//  DepartureCard+Content.swift
//  TripGoAppKit
//
//  Created by Kuan Lun Huang on 28/3/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

public struct DepartureCardContentModel {
  
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

extension DepartureCardContentModel {
  
  static func build(for visit: StopVisits, hideAlerts: Bool = false) -> DepartureCardContentModel? {
    guard let service = (visit.service as Service?) else {
      return nil
    }
    
    var model = DepartureCardContentModel(title: visit.buildTitle())
    
    model.servicePlaceholderImage = service.modeImage(for: .listMainMode)
    model.serviceImageURL = service.modeImageURL(for: .listMainMode)
    model.serviceImageIsTemplate = service.modeImageIsTemplate
//    model.serviceImageIsColorCoded = TGWhiteLabel.shared.styleSource.colorCodingTransitIcon
    model.serviceLineColor = service.color as? UIColor
    model.subtitle = visit.secondaryInformation()
    model.subsubtitle = visit.realTimeInformation(true)
    model.approximateTimeToDepart = visit.countdownDate()
    model.serviceIsCancelled = service.isCancelled
    
    // Accessibility section
    model.requiresAccessibilitySupport = TKUserProfileHelper.showWheelchairInformation
    if let isStopAccessible = visit.stop.isWheelchairAccessible {
      model.serviceIsAccessible = isStopAccessible && service.isWheelchairAccessible
    } else if service.isWheelchairAccessible {
      model.serviceIsAccessible = true
    } else {
      model.serviceIsAccessible = nil
    }
    
    // Service alert section
    if !hideAlerts {
      model.serviceAlerts = service.allAlerts()
    }
    
    // Realtime occupancies
    model.serviceOccupancies = service.vehicle?.rx.components
      .map { $0.map { $0.map { $0.occupancy ?? .unknown } } }
    
    return model
  }
  
}

// MARK: - Protocol conformance
extension DepartureCardContentModel: TKUIDepartureCellContentDataSource {
  
  public var placeHolderImage: UIImage? { return servicePlaceholderImage }
  public var imageURL: URL? { return serviceImageURL }
  public var imageIsTemplate: Bool { return serviceImageIsTemplate }
  public var imageTintColor: UIColor? { return serviceImageIsColorCoded ? serviceLineColor : nil }
  public var lineColor: UIColor? { return serviceLineColor }
  public var alerts: [Alert] { return serviceAlerts }
  public var vehicleOccupancies: Observable<[[API.VehicleOccupancy]]>? { return serviceOccupancies }
  
  public var accessibilityDisplaySetting: TKUIAccessibilityDisplaySetting {
    if requiresAccessibilitySupport {
      return .enabled(serviceIsAccessible)
    } else {
      return .disabled
    }
  }
  
}

// MARK: -
extension StopVisits {
  
  fileprivate func buildTitle() -> NSAttributedString {
    var title = ""
    
    // Do we have a service number?
    var number: String?
    
    if let serviceNumber = service.number, !serviceNumber.isEmpty {
      number = serviceNumber
    }
    
    // Frequency based service
    switch timing {
    case .frequencyBased(let frequency, _, _, _):
      let freqString = Date.durationString(forMinutes: Int(frequency / 60))
      
      if let number = number {
        // Add service number as a prefix
        title = Loc.Every(prefix: number, repetition: freqString)
      } else {
        title = Loc.Every(repetition: freqString)
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
          if let number = number {
            title = String(format: "%@: %@", number, departureString)
          } else {
            title = departureString
          }
        }
        
        var arrivalString = ""
        if let arrivalDate = arrival {
          arrivalString = TKStyleManager.timeString(arrivalDate, for: timeZone)
        }
        
        if !arrivalString.isEmpty {
          title = title + String(format: " - %@", arrivalString)
        }
        
      } else if !departureString.isEmpty {
        if let number = number {
          title = Loc.At(what: number, time: departureString)
        } else {
          title = Loc.At(time: departureString)
        }
      }
    }
    
    return NSAttributedString(string: title)
  }
  
}
