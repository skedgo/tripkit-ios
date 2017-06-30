//
//  STKRoutePolyline.swift
//  Pods
//
//  Created by Adrian Schoenig on 27/10/16.
//
//

import Foundation
import CoreLocation

fileprivate class WrappedCoordinate {
  fileprivate let coordinate: CLLocationCoordinate2D
  init(_ coordinate: CLLocationCoordinate2D) {
    self.coordinate = coordinate
  }
}

extension MKGeodesicPolyline : STKDisplayableRoute {

  public func routePath() -> [Any] {
    var coordinates = [CLLocationCoordinate2D]()
    coordinates.reserveCapacity(pointCount)
    getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
    return coordinates.map { WrappedCoordinate($0) }
  }
  
  public func routeColour() -> UIColor? {
    return nil
  }
  
}
