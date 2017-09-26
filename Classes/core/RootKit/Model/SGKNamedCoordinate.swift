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
    isDraggable = (try? container.decode(Bool.self, forKey: .isDraggable)) ?? false
    isSuburb = (try? container.decode(Bool.self, forKey: .isSuburb)) ?? false

    if let encodedData = try? container.decode(Data.self, forKey: .data), let data = try JSONSerialization.jsonObject(with: encodedData, options: []) as? [String: Any] {
      self.data = data
    } else {
      self.data = [:]
    }
    
    // TODO: Should we include placemark here? What happens if we don't?
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(coordinate.latitude, forKey: .latitude)
    try container.encode(coordinate.longitude, forKey: .longitude)
    try container.encode(name, forKey: .name)
    try container.encode(address, forKey: .address)
    try container.encode(locationID, forKey: .locationID)
    try container.encode(isDraggable, forKey: .isDraggable)
    try container.encode(isSuburb, forKey: .isSuburb)

    let encodedData = try JSONSerialization.data(withJSONObject: data, options: [])
    try container.encode(encodedData, forKey: .data)
  }
  
  // MARK: - NSSecureCoding
  
  @objc
  public static var supportsSecureCoding: Bool { return true }
  
  @objc
  public required init?(coder aDecoder: NSCoder) {
    if let data = aDecoder.decodeData() {
      // The new way
      do {
        let decoded = try JSONDecoder().decode(SGKNamedCoordinate.self, from: data)
        self.coordinate = decoded.coordinate
        self.name = decoded.name
        self._address = decoded.address
        self.locationID = decoded.locationID
        self.data = decoded.data
        self.isSuburb = decoded.isSuburb
        self.isDraggable = decoded.isDraggable
      } catch {
        assertionFailure("Couldn't decode due to: \(error)")
        return nil
      }

    } else {
      // For backwards compatibility
      coordinate = CLLocationCoordinate2D(latitude: aDecoder.decodeDouble(forKey: "latitude"), longitude: aDecoder.decodeDouble(forKey: "longitude"))
      name = aDecoder.decodeObject(forKey: "name") as? String
      _address = aDecoder.decodeObject(forKey: "address") as? String
      locationID = aDecoder.decodeObject(forKey: "locationID") as? String
      data = aDecoder.decodeObject(forKey: "data") as? [String: Any] ?? [:]
      _placemark = aDecoder.decodeObject(forKey: "placemark") as? CLPlacemark
      isDraggable = aDecoder.decodeBool(forKey: "isDraggable")
      isSuburb = aDecoder.decodeBool(forKey: "isSuburb")
    }
  }
  
  @objc(encodeWithCoder:)
  open func encode(with aCoder: NSCoder) {
    guard let data = try? JSONEncoder().encode(self) else { return }
    aCoder.encode(data)
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
