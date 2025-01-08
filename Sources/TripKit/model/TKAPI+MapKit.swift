//
//  TKAPI+MapKit.swift
//  TripKit
//
//  Created by Adrian Schönig on 19/11/2024.
//

import MapKit

extension TKAPI.Location {
  
  public init(annotation: MKAnnotation) {
    self.init(
      latitude: annotation.coordinate.latitude,
      longitude: annotation.coordinate.longitude,
      bearing: nil,
      name: annotation.title ?? nil,
      address: annotation.subtitle ?? nil
    )
  }
  
}

extension TKNamedCoordinate {
  public convenience init(_ remote: TKAPI.Location) {
    self.init(
      latitude: remote.latitude,
      longitude: remote.longitude,
      name: remote.name,
      address: remote.address
    )
  }
}
