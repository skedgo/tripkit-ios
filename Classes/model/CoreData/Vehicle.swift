//
//  Vehicle.swift
//  TripKit
//
//  Created by Adrian Schoenig on 17/10/16.
//
//

import Foundation

extension TKOccupancy {
  
  public var color: SGKColor? {
    
    switch self {
    case .unknown:
      return nil
    case .empty, .manySeatsAvailable:
      return SGKColor(red: 23/255.0, green: 177/255.0, blue: 94/255.0, alpha: 1)
    case .fewSeatsAvailable:
      return SGKColor(red: 255/255.0, green: 181/255.0, blue: 0/255.0, alpha: 1)
    case .standingRoomOnly, .crushedStandingRoomOnly:
      return SGKColor(red: 255/255.0, green: 150/255.0, blue: 0/255.0, alpha: 1)
    case .full, .notAcceptingPassengers:
      return SGKColor(red: 255/255.0, green: 75/255.0, blue: 71/255.0, alpha: 1)
    }
    
  }
  
}

extension Vehicle {
  
  public var occupancy: TKOccupancy? {
    get {
      if let raw = occupancyRaw?.intValue, let converted = TKOccupancy(rawValue: raw) {
        return converted
      } else {
        return nil
      }
    }
    set {
      if let occupancy = newValue {
        occupancyRaw = NSNumber(value: occupancy.rawValue)
      } else {
        occupancyRaw = nil
      }
    }
  }
  
  public var isWifiEnabled: Bool? {
    return wifi?.boolValue
  }
  
  public var serviceNumber: String? {
    return anyService?.number
  }
  
  public var serviceColor: SGKColor? {
    return occupancy?.color
  }
  
  public var ageFactor: Double {
    guard let age = lastUpdate?.timeIntervalSinceNow, age < -120 else { return 0 }
    
    // vehicle is more than 2 minutes old. start fading it out
    return min(1, (-age - 120) / (300 - 120))
  }
  
  fileprivate var anyService: Service? {
    return service ?? serviceAlternatives.first
  }
  
  fileprivate var anySegmentReference: SegmentReference? {
    return segment ?? segmentAlternatives.first
  }
  
}

// MARK: - MKAnnotation

extension Vehicle : MKAnnotation {
  
  public var coordinate: CLLocationCoordinate2D {
    guard let lat = latitude?.doubleValue, let lng = longitude?.doubleValue else {
      return kCLLocationCoordinate2DInvalid
    }
    
    return CLLocationCoordinate2D(latitude: lat, longitude: lng)
  }
  
  public func setCoordinate(_ newValue: CLLocationCoordinate2D) {
    latitude = NSNumber(value: newValue.latitude)
    longitude = NSNumber(value: newValue.longitude)
  }
  
  public var title: String? {
    guard let modeTitle =
      anyService?.modeTitle?.capitalized(with: Locale.current)
      ?? anySegmentReference?.template()?.modeInfo?.descriptor
      ?? label
      else { return nil }
    
    if let number = service?.number {
      return "\(modeTitle) \(number)"
    } else {
      return modeTitle
    }
  }
  
  public var subtitle: String? {
    return [updatedTitle, occupancy?.description]
      .flatMap { $0 }
      .joined(separator: " - ")
  }
  
  private var updatedTitle: String? {
    guard let seconds = self.lastUpdate?.timeIntervalSinceNow else { return nil }
    
    let duration = Date.durationString(forSeconds: -seconds)
    if let label = self.label, (1...20).contains(label.utf16.count) {
      let format = NSLocalizedString("Vehicle %@ updated %@ ago", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Vehicle 'x' updated. (old key: VehicleCalledUpdated)")
      return String(format: format, label, duration)
    } else {
      let format = NSLocalizedString("Updated %@ ago", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Vehicle updated. (old key: VehicleUpdated)")
      return String(format: format, duration)
    }
  }
  
}
