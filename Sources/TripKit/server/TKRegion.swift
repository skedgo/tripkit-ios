//
//  TKRegion.swift
//  TripKit
//
//  Created by Adrian Schoenig on 3/1/17.
//
//

import Foundation

#if canImport(MapKit)
import CoreLocation
import MapKit
#endif

enum TKRegionParserError : Error {
  case emptyPolygon
  case badTimeZoneIdentifier(String)
  case cannotParseInternationalRegion
}

public class TKRegion : NSObject, Codable {
  
  public static let international = TKInternationalRegion()

  public class City : NSObject, Codable {
    public let title: String?
    public let latitude: TKAPI.Degrees
    public let longitude: TKAPI.Degrees

    public weak var region: TKRegion? = nil
    public var orderInRegion: Int? = nil

    // This shouldn't be necessary, but there were reports of crashes when
    // calling `[MKMapView removeAnnotations:]`:
    //
    //      Terminating app due to uncaught exception 'NSUnknownKeyException',
    //      reason: '[<TKRegionCity 0x7f957975d000> valueForUndefinedKey:]: this
    //      class is not key value coding-compliant for the key subtitle.'
    public let subtitle: String? = nil
    
    public init(title: String, latitude: TKAPI.Degrees, longitude: TKAPI.Degrees) {
      self.title = title
      self.latitude = latitude
      self.longitude = longitude
    }
    
    // MARK: Codable
    
    private enum CodingKeys: String, CodingKey {
      case lat
      case lng
      case title
    }
    
    public required init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      title = try container.decode(String.self, forKey: .title)
      latitude = try container.decode(TKAPI.Degrees.self, forKey: .lat)
      longitude = try container.decode(TKAPI.Degrees.self, forKey: .lng)
    }
    
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(latitude, forKey: .lat)
      try container.encode(longitude, forKey: .lng)
      try container.encode(title, forKey: .title)
    }
  }
  
  public let timeZone: TimeZone
  public let code: String
  public let cities: [City]
  
  @available(*, deprecated, renamed: "code")
  public var name: String { code }
  
  /// A list of all the mode identifiers this region supports. This is sorted as defined by the server, as the server groups and sorts them in a sensible manner and we want to preserve this sorting.
  public let modeIdentifiers: [String]

  public let urls: [URL]
  let encodedPolygon: String
  
#if canImport(MapKit)
  public lazy var polygon: MKPolygon = {
    simplePolygon?.polygon ?? MKPolygon()
  }()
#endif

  private let simplePolygon: Polygon?
  
  /// - warning: Only use this for testing purposes, do not pass
  ///     instances created this way to methods that needs
  ///     a region. Instead use the various helpers in
  ///     `TKRegionManager` instead.
  ///
  public init(forTestingWithCode code: String, modes: [String], cities: [City]) {
    self.code = code
    self.modeIdentifiers = modes
    self.cities = cities
    self.urls = []
    self.encodedPolygon = ""
    self.simplePolygon = nil
    self.timeZone = .current
  }
  
  fileprivate init(asInternationalWithCode code: String, modes: [String]) {
    encodedPolygon        = ""
    simplePolygon         = nil
    self.code             = code
    urls                  = []
    timeZone              = .current
    cities                = []
    self.modeIdentifiers  = modes
  }
  
#if canImport(MapKit)
  @objc(containsCoordinate:)
  public func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
    guard let polygon = simplePolygon else { return false }
    let point = Point(latitude: coordinate.latitude, longitude: coordinate.longitude)
    return polygon.contains(point, onLine: false)
  }
  
  @objc(intersectsMapRect:)
  public func intersects(_ mapRect: MKMapRect) -> Bool {
    // Fast check, based on bounding boxes
    guard polygon.intersects(mapRect) else { return false }
    
    // Detailed check on actual polygon
    guard let simplePolygon = simplePolygon else { return true }
    
    let needle = Polygon(
      points: [
        MKMapPoint(x: mapRect.minX, y: mapRect.minY),
        MKMapPoint(x: mapRect.minX, y: mapRect.maxY),
        MKMapPoint(x: mapRect.maxX, y: mapRect.maxY),
        MKMapPoint(x: mapRect.maxX, y: mapRect.minY),
      ]
      .map(\.coordinate)
      .map { Point(latitude: $0.latitude, longitude: $0.longitude) }
    )
    return simplePolygon.contains(needle)
        || needle.contains(simplePolygon)
        || simplePolygon.intersects(needle)
  }
#endif
  
  // MARK: Codable
  
  private enum CodingKeys: String, CodingKey {
    case timeZone = "timezone"
    case code = "name"
    case cities
    case modeIdentifiers = "modes"
    case urls
    case encodedPolygon = "polygon"
  }
  
  public required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    code = try container.decode(String.self, forKey: .code)
    cities = try container.decode([City].self, forKey: .cities)
    modeIdentifiers = try container.decode([String].self, forKey: .modeIdentifiers)
    urls = try container.decode([URL].self, forKey: .urls)
    
    encodedPolygon = try container.decode(String.self, forKey: .encodedPolygon)
    if encodedPolygon.count == 0 {
      throw TKRegionParserError.emptyPolygon
    }

    let identifier = try container.decode(String.self, forKey: .timeZone)
    if let timeZone = TimeZone(identifier: identifier) {
      self.timeZone = timeZone
    } else {
      throw TKRegionParserError.badTimeZoneIdentifier(identifier)
    }
    
    simplePolygon = Polygon(points: Point.decodePolyline(encodedPolygon))
    
    super.init()
    
    for (index, city) in cities.enumerated() {
      city.region = self
      city.orderInRegion = index
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(timeZone.identifier, forKey: .timeZone)
    try container.encode(code, forKey: .code)
    try container.encode(cities, forKey: .cities)
    try container.encode(modeIdentifiers, forKey: .modeIdentifiers)
    try container.encode(urls, forKey: .urls)
    try container.encode(encodedPolygon, forKey: .encodedPolygon)
  }

}

#if canImport(MapKit)
extension TKRegion.City {
  public init(title: String, coordinate: CLLocationCoordinate2D) {
    self.title = title
    self.latitude = coordinate.latitude
    self.longitude = coordinate.longitude
  }

  @objc public var centerBiasedMapRect: MKMapRect {
    // centre it on the region's coordinate
    let size = MKMapSize(width: 300_000, height: 400_00)
    var center = MKMapPoint(coordinate)
    center.x -= size.width / 2
    center.y -= size.height / 2
    return MKMapRect(origin: center, size: size)
  }
}

extension TKRegion.City: MKAnnotation {
  public var coordinate: CLLocationCoordinate2D {
    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
}
#endif


public class TKInternationalRegion : TKRegion {
  
  fileprivate init() {
    let modes: [TKTransportMode] = [
      .flight,
      .publicTransport,
      .car,
      .motorbike,
    ]
    super.init(asInternationalWithCode: "International", modes: modes.map(\.modeIdentifier))
  }
  
  public required init(from decoder: Decoder) throws {
    throw TKRegionParserError.cannotParseInternationalRegion
  }
  
#if canImport(MapKit)
  override public func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
    return coordinate.isValid
  }
#endif
}

@available(*, unavailable, renamed: "TKRegion")
public typealias SVKRegion = TKRegion

@available(*, unavailable, renamed: "TKInternationalRegion")
public typealias SVKInternationalRegion = TKInternationalRegion




