//
//  TKGeoJSON+NamedCoordinate.swift
//  TripKit
//
//  Created by Adrian Schoenig on 03.10.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension TKGeoJSON {
  
  func toNamedCoordinates() -> [SGKNamedCoordinate] {
    switch self {
    case .collection(let features):
      return features.compactMap(SGKNamedCoordinate.init(from:))
    case .feature(let feature):
      if let coordinate = SGKNamedCoordinate(from: feature) {
        return [coordinate]
      } else {
        return []
      }
    }
  }
  
}

extension SGKNamedCoordinate {
  
  fileprivate convenience init?(from geojson: TKGeoJSON.Feature) {
    switch geojson.geometry {
    case .point(let position):
      let mapZen = geojson.properties as? TKPeliasProperties
      
      self.init(latitude: position.latitude, longitude: position.longitude, name: mapZen?.name, address: mapZen?.label)
      
      clusterIdentifier = mapZen?.layer
      dataSources = mapZen?.dataSources ?? []
      
    default:
      return nil
    }
  }

}

extension TKPeliasProperties {
  
  private static let mapZenAttribution = API.DataAttribution(provider: API.CompanyInfo(name: "MapZen", website: URL(string: "https://mapzen.com")))
  
  private var specificSource: API.DataAttribution? {
    guard let source = source else { return nil }
    switch source {
    case "openaddresses", "oa":
      return API.DataAttribution(provider: API.CompanyInfo(name: "OpenAddresses", website: URL(string: "http://openaddresses.io/")))
      
    case "whosonfirst", "wof":
      return API.DataAttribution(provider: API.CompanyInfo(name: "Who's on First", website: URL(string: "https://whosonfirst.mapzen.com/")), disclaimer: "License available at http://whosonfirst.mapzen.com#License")

    case "openstreetmap", "osm":
      return API.DataAttribution(provider: API.CompanyInfo(name: "OpenStreetMap", website: URL(string: "https://openstreetmap.org")))

    case "geonames", "gn":
      return API.DataAttribution(provider: API.CompanyInfo(name: "GeoNames", website: URL(string: "http://www.geonames.org/")))
      
    default:
      assertionFailure("Attribution not handled: \(source)")
      return nil
    }
  }
  
  var dataSources: [API.DataAttribution] {
    var attributions = [TKPeliasProperties.mapZenAttribution]
    if let specificSource = self.specificSource {
      attributions.append(specificSource)
    }
    return attributions
  }
  
}
