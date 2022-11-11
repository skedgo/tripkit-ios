//
//  TKNamedCoordinate.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 25/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation
import MapKit

open class TKNamedCoordinate : NSObject, NSSecureCoding, Codable, TKClusterable {
  
  public fileprivate(set) var coordinate: CLLocationCoordinate2D {
    didSet {
      _address = nil
      _placemark = nil
    }
  }
  
  @objc
  public var clusterIdentifier: String? = nil
  
  @objc public var name: String? = nil
  
  @objc public var _address: String? = nil
  @objc public var address: String? {
    get {
      // this will call the lazy placemark getter, which will set the address
      guard _address == nil, let placemark = self.placemark else { return _address }
      
      _address = placemark.address()
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
      self._address = placemark.address()
      
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
  @objc public var timeZoneID: String? = nil
  
  @objc public var timeZone: TimeZone? {
    timeZoneID.flatMap(TimeZone.init(identifier:))
  }
  
  @objc public var isDraggable: Bool = false
  
  @objc public var isSuburb: Bool = false
  
  @objc(namedCoordinateForAnnotation:)
  public static func namedCoordinate(for annotation: MKAnnotation) -> TKNamedCoordinate {
    if let named = annotation as? TKNamedCoordinate {
      return named
    }
    
    let coordinate = annotation.coordinate
    if let name = annotation.title ?? nil,
       let address = annotation.subtitle ?? nil {
      return TKNamedCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude, name: name, address: address)
    } else {
      return TKNamedCoordinate(coordinate: coordinate)
    }
  }
  
  @objc public init(latitude: CLLocationDegrees, longitude: CLLocationDegrees, name: String?, address: String?) {
    coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    self.name = name
    _address = address
  }
  
  @objc public init(placemark: CLPlacemark) {
    if let name = placemark.name {
      self.name = name
    } else if let poi = placemark.areasOfInterest?.first {
      self.name = poi
    } else {
      self.name = nil
    }
    
    coordinate = placemark.location?.coordinate ?? kCLLocationCoordinate2DInvalid
    _address = placemark.address()
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
  
  convenience init(from: TKAPI.Location) {
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
    case timeZoneID = "timeZone"
    case data
    case placemark
    case isDraggable
    case isSuburb
    case clusterIdentifier
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
    timeZoneID = try? container.decode(String.self, forKey: .timeZoneID)
    clusterIdentifier = try? container.decode(String.self, forKey: .clusterIdentifier)
    isDraggable = (try? container.decode(Bool.self, forKey: .isDraggable)) ?? false
    isSuburb = (try? container.decode(Bool.self, forKey: .isSuburb)) ?? false

    if let encodedData = try? container.decode(Data.self, forKey: .data), let data = try JSONSerialization.jsonObject(with: encodedData, options: []) as? [String: Any] {
      self.data = data
    } else {
      self.data = [:]
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(coordinate.latitude, forKey: .latitude)
    try container.encode(coordinate.longitude, forKey: .longitude)
    try container.encode(name, forKey: .name)
    try container.encode(address, forKey: .address)
    try container.encode(locationID, forKey: .locationID)
    try container.encode(timeZoneID, forKey: .timeZoneID)
    try container.encode(clusterIdentifier, forKey: .clusterIdentifier)
    try container.encode(isDraggable, forKey: .isDraggable)
    try container.encode(isSuburb, forKey: .isSuburb)

    if let sanitized = TKJSONSanitizer.sanitize(data) {
      let encodedData = try JSONSerialization.data(withJSONObject: sanitized, options: [])
      try container.encode(encodedData, forKey: .data)
    }
  }
  
  // MARK: - NSSecureCoding
  
  @objc public class var supportsSecureCoding: Bool { true }
  
  @objc
  public required init?(coder aDecoder: NSCoder) {
    if let data = aDecoder.decodeData() {
      // For backwards compatibility
      do {
        let decoded = try JSONDecoder().decode(TKNamedCoordinate.self, from: data)
        self.coordinate = decoded.coordinate
        self.name = decoded.name
        self._address = decoded.address
        self.locationID = decoded.locationID
        self.timeZoneID = decoded.timeZoneID
        self.clusterIdentifier = decoded.clusterIdentifier
        self.data = decoded.data
        self.isSuburb = decoded.isSuburb
        self.isDraggable = decoded.isDraggable
      } catch {
        assertionFailure("Couldn't decode due to: \(error)")
        return nil
      }

    } else {
      // The new way, supporting secure coding
      let latitude = aDecoder.decodeDouble(forKey: "latitude")
      let longitude = aDecoder.decodeDouble(forKey: "longitude")
      if abs(latitude) < 0.01, abs(longitude) < 0.01 {
        return nil // possiblity from when they weren't safely encoded
      }
      coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      name = aDecoder.decodeObject(of: NSString.self, forKey: "name") as String?
      _address = aDecoder.decodeObject(of: NSString.self, forKey: "address") as String?
      locationID = aDecoder.decodeObject(of: NSString.self, forKey: "locationID") as String?
      timeZoneID = aDecoder.decodeObject(of: NSString.self, forKey: "timeZone") as String?
      clusterIdentifier = aDecoder.decodeObject(of: NSString.self, forKey: "clusterIdentifier") as String?
      _placemark = aDecoder.decodeObject(of: CLPlacemark.self, forKey: "placemark")
      isDraggable = aDecoder.decodeBool(forKey: "isDraggable")
      isSuburb = aDecoder.decodeBool(forKey: "isSuburb")
      data = aDecoder.decodeObject(of: [
          NSDictionary.self,
          NSArray.self,
          NSString.self,
          NSNumber.self,
        ], forKey: "data") as? [String: Any] ?? [:]
    }
  }
  
  @objc(encodeWithCoder:)
  open func encode(with aCoder: NSCoder) {
    aCoder.encode(coordinate.latitude, forKey: "latitude")
    aCoder.encode(coordinate.longitude, forKey: "longitude")
    aCoder.encode(name, forKey: "name")
    aCoder.encode(address, forKey: "address")
    aCoder.encode(locationID, forKey: "locationID")
    aCoder.encode(timeZoneID, forKey: "timeZone")
    aCoder.encode(clusterIdentifier, forKey: "clusterIdentifier")
    aCoder.encode(_placemark, forKey: "placemark")
    aCoder.encode(isDraggable, forKey: "isDraggable")
    aCoder.encode(isSuburb, forKey: "isSuburb")
    aCoder.encode(data, forKey: "data")
  }

}

fileprivate extension CLPlacemark {
  func address() -> String? {
    TKAddressFormatter.singleLineAddress(for: self)
  }
}

extension TKNamedCoordinate {
  
  @objc public var phone: String? {
    get { return data["phone"] as? String }
    set { data["phone"] = newValue }
  }
  
  @objc public var url: URL? {
    get {
      guard let urlString = data["url"] as? String else { return nil }
      return URL(string: urlString)
    }
    set { data["url"] = newValue?.absoluteString }
  }
  
  @objc public var isDropped: Bool {
    get { return (data["dropped"] as? Bool) ?? false }
    set { data["dropped"] = newValue }
  }
  
}

// MARK: - TKSortableAnnotation & MKAnnotation

extension TKNamedCoordinate: TKSortableAnnotation {
  
  public var title: String? {
    get {
      if let name = self.name, !name.isEmpty {
        return name
      } else if let address = self.address, !address.isEmpty {
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
      if let name = self.name, !name.isEmpty {
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

extension TKNamedCoordinate: TKGeocodable {
  
  public var addressForGeocoding: String? { return address }
  
  public var needsForwardGeocoding: Bool { return !coordinate.isValid }
  
  public func assign(_ coordinate: CLLocationCoordinate2D, forAddress address: String) {
    self.coordinate = coordinate
    _address = address
  }
  
}
