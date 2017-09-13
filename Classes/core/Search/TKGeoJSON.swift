//
//  TKGeoJSON.swift
//  TripKit
//
//  Created by Adrian Schoenig on 12.09.17.
//

import Foundation

import CoreLocation

/// Top-level struct representing a GeoJSON, which
/// is either a (geometrical) feature or a collection
/// there-of.
///
/// For specs see https://tools.ietf.org/html/rfc7946
///
/// - collection: GeoJSON's "FeatureCollection" type
/// - feature: GeoJSON's "Feature" type
public enum TKGeoJSON {

  case collection([Feature])
  case feature(Feature)
  
  /// Details of a geometrical Feature
  public struct Feature {
    let geometry: Geometry
    let properties: Decodable?
  }
  
  public struct Position {
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let altitude: CLLocationDistance?
  }
  
  public enum Geometry {
    case point(Position)
    case lineString([Position])
    case polygon([Position])
  }
  
}

/// Properties used by MapZen's geocoding
public struct TKMapZenProperties: Decodable {
  let gid: String?
  let source: String?
  
  let name: String
  let label: String
  let distance: CLLocationDistance
  let layer: String? // e.g., address or venue or locality
  
  let country: String? // United States
  let region: String? // Pennsylvania
  let macrocountry: String? // e.g., Mittelfranken
  let county: String? // Some county
  let localadmin: String?
  
}

// MARK: - Codable

extension TKGeoJSON: Decodable {
  
  public enum DecodingError: Error {
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
    
    if let mapZen = try? values.decode(TKMapZenProperties.self, forKey: .properties) {
      self.properties = mapZen
    } else {
      self.properties = nil
    }
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
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let type = try values.decode(GeometryType.self, forKey: .type)
    let coordinates = try values.decode(Array<CLLocationDegrees>.self, forKey: .coordinates)
    
    switch type {
    case .point:
      guard coordinates.count >= 2 else { throw TKGeoJSON.DecodingError.missingCoordinates }
      let altitude = coordinates.count >= 3 ? coordinates[2] : nil
      let position = TKGeoJSON.Position(latitude: coordinates[0], longitude: coordinates[1], altitude: altitude)
      self = .point(position)
      
    default:
      throw TKGeoJSON.DecodingError.missingCoordinates
    }
  }
  
}
