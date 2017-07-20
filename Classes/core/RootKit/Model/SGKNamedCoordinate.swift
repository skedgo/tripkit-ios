//
//  SGKNamedCoordinate.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 25/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation
import MapKit

import Marshal

open class SGKNamedCoordinate : NSObject, NSSecureCoding, Unmarshaling {
  
  public fileprivate(set) var coordinate: CLLocationCoordinate2D {
    didSet {
      _address = nil
      _placemark = nil
    }
  }
  
  public var name: String? = nil
  
  public var _address: String? = nil
  public var address: String? {
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
  
  public var data: [String: Any] = [:]
  
  private var _placemark: CLPlacemark? = nil
  public var placemark: CLPlacemark? {
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
  
  public var locationID: String? = nil
  
  public var isDraggable: Bool = false
  
  public var isSuburb: Bool = false
  
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
  
  public init(latitude: CLLocationDegrees, longitude: CLLocationDegrees, name: String?, address: String?) {
    coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    self.name = name
    _address = address
  }
  
  public init(placemark: CLPlacemark) {
    coordinate = placemark.location?.coordinate ?? kCLLocationCoordinate2DInvalid
    name = SGLocationHelper.name(from: placemark)
    _address = SGLocationHelper.address(for: placemark)
    _placemark = placemark
  }
  
  public init(coordinate: CLLocationCoordinate2D) {
    self.coordinate = coordinate
  }
  
  
  public init(name: String?, address: String?) {
    self.coordinate = kCLLocationCoordinate2DInvalid
    self.name = name
    _address = address
  }

  // MARK: - NSSecureCoding
  
  public static var supportsSecureCoding: Bool { return true }
  
  open func encode(with aCoder: NSCoder) {
    aCoder.encode(coordinate.latitude, forKey: "latitude")
    aCoder.encode(coordinate.longitude, forKey: "longitude")
    aCoder.encode(name, forKey: "name")
    aCoder.encode(address, forKey: "address")
    aCoder.encode(locationID, forKey: "locationID")
    aCoder.encode(data, forKey: "data")
    aCoder.encode(_placemark, forKey: "placemark")
    aCoder.encode(isDraggable, forKey: "isDraggable")
    aCoder.encode(isSuburb, forKey: "isSuburb")
  }

  public required init?(coder aDecoder: NSCoder) {
    coordinate = CLLocationCoordinate2D(latitude: aDecoder.decodeDouble(forKey: "latitude"), longitude: aDecoder.decodeDouble(forKey: "longitude"))
    name = aDecoder.decodeObject(forKey: "name") as? String
    _address = aDecoder.decodeObject(forKey: "address") as? String
    locationID = aDecoder.decodeObject(forKey: "locationID") as? String
    data = aDecoder.decodeObject(forKey: "data") as? [String: Any] ?? [:]
    _placemark = aDecoder.decodeObject(forKey: "placemark") as? CLPlacemark
    isDraggable = aDecoder.decodeBool(forKey: "isDraggable")
    isSuburb = aDecoder.decodeBool(forKey: "isSuburb")
  }
  
  // MARK: - Unmarshaling
  
  public required init(object: MarshaledObject) throws {
    let lat: Double = try object.value(for: "lat")
    let lng: Double = try object.value(for: "lng")
    coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
    
    locationID  = try? object.value(for: "id")
    name        = try? object.value(for: "name")
    _address    = try? object.value(for: "address")
    super.init()

    phone       = try? object.value(for: "phone")
    url         = try? object.value(for: "URL")
  }

}

extension SGKNamedCoordinate {
  
  public var phone: String? {
    get { return data["phone"] as? String }
    set { data["phone"] = newValue }
  }
  
  public var url: URL? {
    get { return data["url"] as? URL }
    set { data["url"] = newValue }
  }
  
  public var isDropped: Bool {
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
