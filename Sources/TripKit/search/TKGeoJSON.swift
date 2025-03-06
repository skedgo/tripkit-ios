//
//  TKGeoJSON.swift
//  TripKit
//
//  Created by Adrian Schoenig on 12.09.17.
//

import Foundation

/// Top-level struct representing a GeoJSON, which
/// is either a (geometrical) feature or a collection
/// there-of.
///
/// For specs see https://tools.ietf.org/html/rfc7946
///
/// - warning: Only implements a subset of GeoJSON
///
/// - collection: GeoJSON's "FeatureCollection" type
/// - feature: GeoJSON's "Feature" type
public enum TKGeoJSON {

  case collection([Feature])
  case feature(Feature)
  
  /// Details of a geometrical Feature
  public struct Feature {
    public let geometry: Geometry
    public let properties: Decodable?
  }
  
  public struct Position: Hashable {
    public let latitude: TKAPI.Degrees
    public let longitude: TKAPI.Degrees
    public let altitude: TKAPI.Distance?
  }
  
  public struct Polygon: Hashable {
    public let exterior: [Position]
    public let interiors: [[Position]]
  }
  
  public enum Geometry: Hashable {
    case point(Position)
    case lineString([Position])
    case polygon(Polygon)
    case multiPolygon([Polygon])
  }
  
}

/// Properties used by Pelias geocoders
struct TKPeliasProperties: Decodable {
  let gid: String?
  let source: String?
  
  let name: String
  let label: String
  let distance: TKAPI.Distance
  let layer: String? // e.g., address or venue or locality
  
  let country: String?        //  United States -     Australia -        Germany
  let country_a: String?      //            USA -           AUS -            DEU
  let neighbourhood: String?  //              - -       Wynyard -            n/a
  let region: String?         //     California -           n/a -         Bayern
  let region_a: String?       //             CA -           n/a -            n/a
  let macrocountry: String?   //            n/a -           n/a -  Mittelfranken
  let county: String?     // Santa Clara County -           n/a -       Nürnberg
  let locality: String?       //      Sunnyvale -           n/a -       Nürnberg
  let localadmin: String?     //            n/a -           n/a -            n/a
  let postalcode: String?
  let street: String?
  let housenumber: String?
  
}

// MARK: - Codable

extension TKGeoJSON: Decodable {
  
  enum DecodingError: Error {
    case missingCoordinates
  }
  
  private enum CodingKeys: String, CodingKey {
    case type
    case features
  }
  
  private enum FeatureType: String, Codable {
    case feature = "Feature"
    case collection = "FeatureCollection"
  }
  
  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let type = try values.decode(FeatureType.self, forKey: .type)
    
    switch type {
    case .feature:
      let feature = try Feature(from: decoder)
      self = .feature(feature)
    case .collection:
      let features = try values.decode(Array<Feature>.self, forKey: .features)
      self = .collection(features)
    }
  }
  
}

extension TKGeoJSON.Feature: Decodable {
  
  private enum CodingKeys: String, CodingKey {
    case geometry
    case properties
  }
  
  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    
    self.geometry = try values.decode(TKGeoJSON.Geometry.self, forKey: .geometry)
    
    if let mapZen = try? values.decode(TKPeliasProperties.self, forKey: .properties) {
      self.properties = mapZen
    } else {
      self.properties = nil
    }
  }
  
}

extension TKGeoJSON.Position {
  init?(_ coordinates: [Double]) {
    guard coordinates.count >= 2 else { return nil }
    let altitude = coordinates.count >= 3 ? coordinates[2] : nil
    self.init(latitude: coordinates[1], longitude: coordinates[0], altitude: altitude)
  }
}

extension TKGeoJSON.Polygon {
  init?(_ coordinates: [[[Double]]]) {
    guard let exterior = coordinates.first else { return nil }
    self.init(
      exterior: exterior.compactMap(TKGeoJSON.Position.init),
      interiors: coordinates.dropFirst().map {
        $0.compactMap(TKGeoJSON.Position.init)
      }
    )
  }
}

extension TKGeoJSON.Geometry: Decodable {

  private enum CodingKeys: String, CodingKey {
    case type
    case coordinates
  }
  
  private enum GeometryType: String, Codable {
    case lineString = "LineString"
    case point = "Point"
    case polygon = "Polygon"
    case multiPolygon = "MultiPolygon"
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let type = try values.decode(GeometryType.self, forKey: .type)
    
    switch type {
    case .point:
      let coordinates = try values.decode([Double].self, forKey: .coordinates)
      guard let position = TKGeoJSON.Position(coordinates) else {
        throw TKGeoJSON.DecodingError.missingCoordinates
      }
      self = .point(position)
      
    case .lineString:
      let coordinates = try values.decode([[Double]].self, forKey: .coordinates)
      self = .lineString(coordinates.compactMap(TKGeoJSON.Position.init))

    case .polygon:
      let coordinates = try values.decode([[[Double]]].self, forKey: .coordinates)
      guard let polygon = TKGeoJSON.Polygon(coordinates) else {
        throw TKGeoJSON.DecodingError.missingCoordinates
      }
      self = .polygon(polygon)
      
    case .multiPolygon:
      let coordinates = try values.decode([[[[Double]]]].self, forKey: .coordinates)
      self = .multiPolygon(coordinates.compactMap(TKGeoJSON.Polygon.init))
    }
  }
  
}
