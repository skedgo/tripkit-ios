//
//  SVKRegion.swift
//  TripKit
//
//  Created by Adrian Schoenig on 3/1/17.
//
//

import Foundation
import CoreLocation
import MapKit

import ASPolygonKit
import Marshal

@objc
public enum SGDistanceUnitType : Int {
  case auto = 0
  case metric
  case imperial
}

enum SVKRegionParserError : Error {
  case emptyPolygon
  case badTimeZoneIdentifier(String)
  case cannotParseInternationalRegion
}

public class SVKRegion : NSObject, NSCoding, Unmarshaling {

  @objc(SVKRegionCity)
  public class City : NSObject, Unmarshaling, MKAnnotation, STKDisplayablePoint {
    public let title: String?
    public let coordinate: CLLocationCoordinate2D
    
    public let isDraggable: Bool = false
    public let pointDisplaysImage: Bool = true
    public let pointImage: SGKImage? = SGStyleManager.imageNamed("icon-map-info-city")
    public var pointImageURL: URL? = nil
    public weak var region: SVKRegion? = nil
    
    public required init(object: MarshaledObject) throws {
      title = try object.value(for: "title")
      
      let latitude: CLLocationDegrees = try object.value(for: "lat")
      let longitude: CLLocationDegrees = try object.value(for: "lng")
      coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public func centerBiasedMapRect() -> MKMapRect {
      // centre it on the region's coordinate
      let size = MKMapSize(width: 300_000, height: 400_00)
      var center = MKMapPointForCoordinate(coordinate)
      center.x -= size.width / 2
      center.y -= size.height / 2
      return MKMapRect(origin: center, size: size)
    }
    
    func encoded() -> [String: Any] {
      return [
        "title": title ?? "",
        "lat": coordinate.latitude,
        "lng": coordinate.longitude,
      ]
    }
  }
  
  public let timeZone: TimeZone
  public let name: String
  public let cities: [City]
  
  /// A list of all the mode identifiers this region supports. This is sorted as defined by the server, as the server groups and sorts them in a sensible manner and we want to preserve this sorting.
  public let modeIdentifiers: [String]

  public let urls: [URL]
  let encodedPolygon: String
  
  lazy var polygon: MKPolygon = {
    let corners = CLLocation.decodePolyLine(self.encodedPolygon)
    let coordinates = corners.map { $0.coordinate }
    return MKPolygon(coordinates: coordinates, count: coordinates.count)
  }()
  
  
  fileprivate init(asInternationalNamed name: String, modes: [String]) {
    encodedPolygon        = ""
    self.name             = name
    urls                  = []
    timeZone              = .current
    cities                = []
    self.modeIdentifiers  = modes
  }
  
  
  // MARK: Unmarshaling
  
  public required init(object: MarshaledObject) throws {
    encodedPolygon  = try object.value(for: ["encodedPolygon", "polygon"])
    name            = try object.value(for: "name")
    urls            = try object.value(for: "urls")
    timeZone        = try object.value(for: "timezone")
    modeIdentifiers = try object.value(for: ["modeIdentifiers", "modes"])
    cities          = try object.value(for: "cities")
    
    if encodedPolygon.characters.count == 0 {
      throw SVKRegionParserError.emptyPolygon
    }
    
    super.init()
    
    cities.forEach { $0.region = self }
  }
  
  
  // MARK: NSCoding

  public required convenience init?(coder aDecoder: NSCoder) {
    do {
      try self.init(object: aDecoder)
    } catch {
      return nil
    }
  }
  

  public func encode(with aCoder: NSCoder) {
    aCoder.encode(name, forKey: "name")
    aCoder.encode(encodedPolygon, forKey: "encodedPolygon")
    aCoder.encode(urls.map { $0.absoluteString }, forKey: "urls")
    aCoder.encode(timeZone as NSTimeZone, forKey: "timezone")
    aCoder.encode(cities.map { $0.encoded() }, forKey: "cities")
    aCoder.encode(modeIdentifiers, forKey: "modeIdentifiers")
  }
  
  
  @objc(containsCoordinate:)
  public func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
    return polygon.contains(coordinate)
  }


  @objc(intersectsMapRect:)
  public func intersects(_ mapRect: MKMapRect) -> Bool {
    return polygon.intersects(mapRect)
  }
  
}


public class SVKInternationalRegion : SVKRegion {
  
  public static let shared: SVKRegion = SVKInternationalRegion()
  
  private init() {
    var modes = [
      SVKTransportModeIdentifierRegularPublicTransport,
      SVKTransportModeIdentifierCar,
      SVKTransportModeIdentifierMotorbike,
    ]
    if UserDefaults.shared.bool(forKey: SVKDefaultsKeyProfileEnableFlights) {
      modes = [SVKTransportModeIdentifierFlight] + modes
    }
    super.init(asInternationalNamed: "International", modes: modes)
  }
  
  public required init(object: MarshaledObject) throws {
    throw SVKRegionParserError.cannotParseInternationalRegion
  }
  
  public required convenience init?(coder aDecoder: NSCoder) {
    return nil
  }
  
  override public func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
    return coordinate.isValid
  }
}


extension TimeZone: ValueType {
  public static func value(from object: Any) throws -> TimeZone {
    if let object = object as? TimeZone {
      return object // can happen when NSCoding was used (i.e., NSTimeZone)
    }
    guard let identifier = object as? String else {
      throw MarshalError.typeMismatch(expected: String.self, actual: type(of: object))
    }
    guard let timeZone = TimeZone(identifier: identifier) else {
      throw SVKRegionParserError.badTimeZoneIdentifier(identifier)
    }
    return timeZone
  }
}


extension MarshaledObject {
  fileprivate func value<A: ValueType>(for keys: [KeyType]) throws -> A {
    for key in keys {
      if let value: A = try? value(for: key) {
        return value
      }
    }
    throw MarshalError.keyNotFound(key: keys.first!)
  }
  
  fileprivate func value<A: ValueType>(for keys: [KeyType]) throws -> [A] {
    for key in keys {
      if let value: [A] = try? value(for: key) {
        return value
      }
    }
    throw MarshalError.keyNotFound(key: keys.first!)
  }
  
}

