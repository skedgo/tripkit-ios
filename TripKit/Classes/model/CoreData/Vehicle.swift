//
//  Vehicle.swift
//  TripKit
//
//  Created by Adrian Schoenig on 17/10/16.
//
//

import Foundation

extension Vehicle {
  
  public var components: [[API.VehicleComponents]]? {
    get {
      if let data = componentsData {
        return try? JSONDecoder().decode([[API.VehicleComponents]].self, from: data)
      } else {
        return nil
      }
    }
    set {
      if let components = newValue {
        componentsData = try? JSONEncoder().encode(components)
      } else {
        componentsData = nil
      }
    }
  }
  
  @objc public var serviceNumber: String? {
    return anyService?.number
  }
  
  @objc public var serviceColor: SGKColor? {
    return averageOccupancy?.color
  }
  
  @objc public var ageFactor: Double {
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
  
  public var averageOccupancy: API.VehicleOccupancy? {
    let components = self.components ?? [[]]
    let occupancies = components
      .reduce(into: []) { $0.append(contentsOf: $1) }
      .flatMap { $0.occupancy }
    if occupancies.isEmpty {
      return nil
    } else if occupancies.count == 1 {
      return occupancies[0]
    }
    
    let sum = occupancies.reduce(0) { $0 + $1.intValue }
    return API.VehicleOccupancy(intValue: sum / occupancies.count)
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
  
  @objc public func setCoordinate(_ newValue: CLLocationCoordinate2D) {
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
    return [updatedTitle, averageOccupancy?.description]
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
