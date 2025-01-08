//
//  MKMultiPoint+ClosestPoint.swift
//  TripKit
//
//  Created by Adrian Schönig on 21.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

#if canImport(MapKit)
import MapKit

public extension MKMultiPoint {

  // Return the point on the polyline that is the closest to the given point
  // along with the distance between that closest point and the given point.
  //
  // Thanks to:
  // http://paulbourke.net/geometry/pointlineplane/
  // https://stackoverflow.com/questions/11713788/how-to-detect-taps-on-mkpolylines-overlays-like-maps-app
  func closestPoint(to: MKMapPoint) -> (point: MKMapPoint, distance: CLLocationDistance) {
    
    var closestPoint = MKMapPoint()
    var distanceTo: CLLocationDistance = .infinity
    
    let points = self.points()
    for i in 0 ..< pointCount - 1 {
      let endPointA = points[i]
      let endPointB = points[i + 1]
      
      let deltaX: Double = endPointB.x - endPointA.x
      let deltaY: Double = endPointB.y - endPointA.y
      if deltaX == 0.0 && deltaY == 0.0 { continue } // Points must not be equal
      
      let u: Double = ((to.x - endPointA.x) * deltaX + (to.y - endPointA.y) * deltaY) / (deltaX * deltaX + deltaY * deltaY) // The magic sauce. See the Paul Bourke link above.
      
      let closest: MKMapPoint
      if u < 0.0 { closest = endPointA }
      else if u > 1.0 { closest = endPointB }
      else { closest = MKMapPoint(x: endPointA.x + u * deltaX, y: endPointA.y + u * deltaY) }
      
      let distance = closest.distance(to: to)
      if distance < distanceTo {
        closestPoint = closest
        distanceTo = distance
      }
    }
    
    return (closestPoint, distanceTo)
  }
}

#endif