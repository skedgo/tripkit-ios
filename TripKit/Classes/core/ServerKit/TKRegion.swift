//
//  TKRegion.swift
//  TripKit
//
//  Created by Adrian Schoenig on 3/1/17.
//
//

import Foundation
import CoreLocation
import MapKit

import ASPolygonKit

enum TKRegionParserError : Error {
  case emptyPolygon
  case badTimeZoneIdentifier(String)
  case cannotParseInternationalRegion
}

public class TKRegion : NSObject, Codable {
  
  @objc public static let international = TKInternationalRegion()

  @objc(TKRegionCity)
  public class City : NSObject, Codable, MKAnnotation, TKDisplayablePoint {
    public let title: String?
    public let coordinate: CLLocationCoordinate2D

    @objc public weak var region: TKRegion? = nil
    public var orderInRegion: Int? = nil

    public let isDraggable: Bool = false
    public let pointDisplaysImage: Bool = true
    public let pointImage: TKImage? = TKStyleManager.imageNamed("icon-map-info-city")
    public var pointImageURL: URL? = nil
    public var pointImageIsTemplate: Bool = false
    public var pointClusterIdentifier: String? = "TKRegion.City"

    @objc public var centerBiasedMapRect: MKMapRect {
      // centre it on the region's coordinate
      let size = MKMapSize(width: 300_000, height: 400_00)
      var center = MKMapPointForCoordinate(coordinate)
      center.x -= size.width / 2
      center.y -= size.height / 2
      return MKMapRect(origin: center, size: size)
    }
    
    public init(title: String, coordinate: CLLocationCoordinate2D) {
      self.title = title
      self.coordinate = coordinate
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
      let latitude = try container.decode(CLLocationDegrees.self, forKey: .lat)
      let longitude = try container.decode(CLLocationDegrees.self, forKey: .lng)
      coordinate = CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(coordinate.latitude, forKey: .lat)
      try container.encode(coordinate.longitude, forKey: .lng)
      try container.encode(title, forKey: .title)
    }
  }
  
  @objc public let timeZone: TimeZone
  @objc public let name: String
  @objc public let cities: [City]
  
  /// A list of all the mode identifiers this region supports. This is sorted as defined by the server, as the server groups and sorts them in a sensible manner and we want to preserve this sorting.
  @objc public let modeIdentifiers: [String]

  @objc public let urls: [URL]
  @objc let encodedPolygon: String
  
  @objc public lazy var polygon: MKPolygon = {
    let corners = CLLocation.decodePolyLine(self.encodedPolygon)
    let coordinates = corners.map { $0.coordinate }
    return MKPolygon(coordinates: coordinates, count: coordinates.count)
  }()
  
  /// - warning: Only use this for testing purposes, do not pass
  ///     instances created this way to methods that needs
  ///     a region. Instead use the various helpers in
  ///     `TKRegionManager` instead.
  ///
  public init(forTestingWithName name: String, modes: [String], cities: [City]) {
    self.name = name
    self.modeIdentifiers = modes
    self.cities = cities
    self.urls = []
    self.encodedPolygon = ""
    self.timeZone = .current
  }
  
  fileprivate init(asInternationalNamed name: String, modes: [String]) {
    encodedPolygon        = ""
    self.name             = name
    urls                  = []
    timeZone              = .current
    cities                = []
    self.modeIdentifiers  = modes
  }
  
  @objc(containsCoordinate:)
  public func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
    return polygon.contains(coordinate)
  }
  
  
  @objc(intersectsMapRect:)
  public func intersects(_ mapRect: MKMapRect) -> Bool {
    return polygon.intersects(mapRect)
  }
  
  // MARK: Codable
  
  private enum CodingKeys: String, CodingKey {
    case timeZone = "timezone"
    case name
    case cities
    case modeIdentifiers = "modes"
    case urls
    case encodedPolygon = "polygon"
  }
  
  public required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    name = try container.decode(String.self, forKey: .name)
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
    
    super.init()
    
    for (index, city) in cities.enumerated() {
      city.region = self
      city.orderInRegion = index
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(timeZone.identifier, forKey: .timeZone)
    try container.encode(name, forKey: .name)
    try container.encode(cities, forKey: .cities)
    try container.encode(modeIdentifiers, forKey: .modeIdentifiers)
    try container.encode(urls, forKey: .urls)
    try container.encode(encodedPolygon, forKey: .encodedPolygon)
  }

}


public class TKInternationalRegion : TKRegion {
  
  fileprivate init() {
    var modes = [
      TKTransportModeIdentifierRegularPublicTransport,
      TKTransportModeIdentifierCar,
      TKTransportModeIdentifierMotorbike,
    ]
    if UserDefaults.shared.bool(forKey: TKDefaultsKeyProfileEnableFlights) {
      modes = [TKTransportModeIdentifierFlight] + modes
    }
    super.init(asInternationalNamed: "International", modes: modes)
  }
  
  public required init(from decoder: Decoder) throws {
    throw TKRegionParserError.cannotParseInternationalRegion
  }
  
  override public func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
    return coordinate.isValid
  }
}




