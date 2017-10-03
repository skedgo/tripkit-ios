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
      return features.flatMap(SGKNamedCoordinate.init(from:))
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
      let mapZen = geojson.properties as? TKMapZenProperties
      
      self.init(latitude: position.latitude, longitude: position.longitude, name: mapZen?.name, address: mapZen?.label)
      
      clusterIdentifier = mapZen?.layer
      
    default:
      return nil
    }
  }

}
