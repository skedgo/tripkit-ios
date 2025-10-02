//
//  TKRegion.swift
//  TripKit
//
//  Created by Adrian Schönig on 19/11/2024.
//

import Foundation

#if canImport(MapKit)
import CoreLocation
import MapKit
#endif

public enum TKRegionParserError : Error {
  case emptyPolygon
  case badTimeZoneIdentifier(String)
  case cannotParseInternationalRegion
  case fetchingRegionsFailed
}

public final class TKRegionCity : NSObject, Codable, @unchecked Sendable {
  public let name: String?
  public let latitude: TKAPI.Degrees
  public let longitude: TKAPI.Degrees

  public init(title: String, latitude: TKAPI.Degrees, longitude: TKAPI.Degrees) {
    self.name = title
    self.latitude = latitude
    self.longitude = longitude
  }
  
  private enum CodingKeys: String, CodingKey {
    case latitude = "lat"
    case longitude = "lng"
    case name = "title"
  }
}

open class TKRegion : NSObject, Codable, @unchecked Sendable {
  public typealias City = TKRegionCity
  
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

  let simplePolygon: Polygon?

  public var isInternational: Bool { simplePolygon == nil }
  
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
  
  public init(asInternationalWithCode code: String, modes: [String]) {
    encodedPolygon        = ""
    simplePolygon         = nil
    self.code             = code
    urls                  = []
    timeZone              = .current
    cities                = []
    self.modeIdentifiers  = modes
  }
  
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

extension TKRegion {
  public func contains(latitude: TKAPI.Degrees, longitude: TKAPI.Degrees) -> Bool {
    guard let simplePolygon else { return false }
    let point = Point(latitude: latitude, longitude: longitude)
    return simplePolygon.contains(point, onLine: false)
  }
  
  public func intersects(polygonPoints: [(latitude: TKAPI.Degrees, longitude: TKAPI.Degrees)]) -> Bool {
    // Detailed check on actual polygon
    guard let simplePolygon else { return true }
    
    let points = polygonPoints.map { Point(latitude: $0.latitude, longitude: $0.longitude) }
    let needle = Polygon(points: points)
    return simplePolygon.contains(needle)
        || needle.contains(simplePolygon)
        || simplePolygon.intersects(needle)

  }
}
