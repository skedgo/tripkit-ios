//
//  SGKNamedCoordinate.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 25/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation
import MapKit

open class SGKNamedCoordinate : NSObject, Codable {
  
  public fileprivate(set) var coordinate: CLLocationCoordinate2D {
    didSet {
      _address = nil
      _placemark = nil
    }
  }
  
  @objc public var name: String? = nil
  
  @objc public var _address: String? = nil
  @objc public var address: String? {
    get {
      // this will call the lazy placemark getter, which will set the address
      guard _address == nil, let placemark = self.placemark else { return _address }
      
      _address = SGLocationHelper.address(for: placemark)
      return _address
    }
    set {
      _address = newValue
    }
  }
  
  @objc public var data: [String: Any] = [:]
  
  private var _placemark: CLPlacemark? = nil
  @objc public var placemark: CLPlacemark? {
    if let placemark = _placemark { return placemark }
    guard coordinate.isValid else { return nil }
    
    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    let geocoder = CLGeocoder()
    
    // no weak self as we're not retaining the geocoder
    geocoder.reverseGeocodeLocation(location) { placemarks, error in
      guard let placemark = placemarks?.first else { return }
      
      self._placemark = placemark
      self._address = SGLocationHelper.address(for: placemark)
      
      // KVO
      if self.name != nil {
        self.subtitle = ""
      } else {
        self.title = ""
      }
    }
    
    return _placemark
  }
  
  @objc public var locationID: String? = nil
  
  @objc public var isDraggable: Bool = false
  
  @objc public var isSuburb: Bool = false
  
  /// - note: Fails if annotation does not have a valid coordinate.
  @objc(namedCoordinateForAnnotation:)
  public static func namedCoordinate(for annotation: MKAnnotation) -> SGKNamedCoordinate? {
    if let named = annotation as? SGKNamedCoordinate {
      return named
    }
    
    let coordinate = annotation.coordinate
    guard coordinate.isValid else {
      return nil
    }
    
    if let name = annotation.title ?? nil,
       let address = annotation.subtitle ?? nil {
      return SGKNamedCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude, name: name, address: address)
    } else {
      return SGKNamedCoordinate(coordinate: coordinate)
    }
  }
  
  @objc public init(latitude: CLLocationDegrees, longitude: CLLocationDegrees, name: String?, address: String?) {
    coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    self.name = name
    _address = address
  }
  
  @objc public init(placemark: CLPlacemark) {
    coordinate = placemark.location?.coordinate ?? kCLLocationCoordinate2DInvalid
    name = SGLocationHelper.name(from: placemark)
    _address = SGLocationHelper.address(for: placemark)
    _placemark = placemark
  }
  
  @objc public init(coordinate: CLLocationCoordinate2D) {
    self.coordinate = coordinate
  }
  
  @objc
  public init(name: String?, address: String?) {
    self.coordinate = kCLLocationCoordinate2DInvalid
    self.name = name
    _address = address
  }
  
  convenience init(from: API.Location) {
    self.init(latitude: from.lat, longitude: from.lng, name: from.name, address: from.address)
  }

  // MARK: - Codable
  
  private enum CodingKeys: String, CodingKey {
    case latitude
    case longitude
    case lat
    case lng
    case name
    case address
    case locationID
    case data
    case placemark
    case isDraggable
    case isSuburb
  }
  
  public required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    // We support both lat/lng and latitude/longitude spellings, making this ugly
    let latitude: CLLocationDegrees
    if let degrees = try? container.decode(CLLocationDegrees.self, forKey: .latitude) {
      latitude = degrees
    } else {
      latitude = try container.decode(CLLocationDegrees.self, forKey: .lat)
    }
    let longitude: CLLocationDegrees
    if let degrees = try? container.decode(CLLocationDegrees.self, forKey: .longitude) {
      longitude = degrees
    } else {
      longitude = try container.decode(CLLocationDegrees.self, forKey: .lng)
    }
    coordinate = CLLocationCoordinate2DMake(latitude, longitude)

    // All of these are often not provide, hence `try?` everywhere
    name = try? container.decode(String.self, forKey: .name)
    _address = try? container.decode(String.self, forKey: .address)
    locationID = try? container.decode(String.self, forKey: .locationID)
    data = (try? container.decode([String: Any].self, forKey: .data)) ?? [:]
    isDraggable = (try? container.decode(Bool.self, forKey: .isDraggable)) ?? false
    isSuburb = (try? container.decode(Bool.self, forKey: .isSuburb)) ?? false
    
    // TODO: Should we include placemark here? What happens if we don't?
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(coordinate.latitude, forKey: .latitude)
    try container.encode(coordinate.longitude, forKey: .longitude)
    try container.encode(name, forKey: .name)
    try container.encode(address, forKey: .address)
    try container.encode(locationID, forKey: .locationID)
    try container.encode(data, forKey: .data)
    try container.encode(isDraggable, forKey: .isDraggable)
    try container.encode(isSuburb, forKey: .isSuburb)
  }

}

extension SGKNamedCoordinate {
  
  @objc public var phone: String? {
    get { return data["phone"] as? String }
    set { data["phone"] = newValue }
  }
  
  @objc public var url: URL? {
    get { return data["url"] as? URL }
    set { data["url"] = newValue }
  }
  
  @objc public var isDropped: Bool {
    get { return (data["dropped"] as? Bool) ?? false }
    set { data["dropped"] = newValue }
  }
  
}

// MARK: - SGKSortableAnnotation & MKAnnotation

extension SGKNamedCoordinate: SGKSortableAnnotation {
  
  public var title: String? {
    get {
      if let name = self.name, name.utf16.count > 0 {
        return name
      } else if let address = self.address, address.utf16.count > 0 {
        return address
      } else {
        return Loc.Location
      }
    }
    set {
      // Nothing to do, just for KVO compliance
    }
  }
  
  public var subtitle: String? {
    get {
      if let name = self.name, name.utf16.count > 0 {
        return address // otherwise the address would be in the title already
      } else {
        return nil
      }
    }
    set {
      // Nothing to do, just for KVO compliance
    }
  }
  
  public var sortScore: Int {
    get { return (data["sortScore"] as? Int) ?? -1 }
    set { data["sortScore"] = newValue }
  }
  
}

extension SGKNamedCoordinate: SGKGeocodable {
  
  public var addressForGeocoding: String? { return address }
  
  public var needsForwardGeocoding: Bool { return !coordinate.isValid }
  
  public func assign(_ coordinate: CLLocationCoordinate2D, forAddress address: String) {
    self.coordinate = coordinate
    _address = address
  }
  
  public var didAttemptGeocodingBefore: Bool {
    get { return (data["didAttemptGeocodingBefore"] as? Bool) ?? false }
    set { data["didAttemptGeocodingBefore"] = newValue }
  }
  
}


extension CLLocationCoordinate2D {
  public var isValid: Bool {
    let suspicious = (abs(latitude) < 0.01 && abs(longitude) < 0.01)
    assert(!suspicious, "Suspicious coordinate: \(self)")
    return CLLocationCoordinate2DIsValid(self) && !suspicious
  }
  
  public func distance(from other: CLLocationCoordinate2D) -> CLLocationDistance? {
    guard isValid && other.isValid else { return nil }
    let me = CLLocation(latitude: latitude, longitude: longitude)
    let you = CLLocation(latitude: other.latitude, longitude: other.longitude)
    return me.distance(from: you)
  }
}
