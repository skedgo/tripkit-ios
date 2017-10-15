//
//  MapKit+Extensions.swift
//  TripKit
//
//  Created by Adrian Schoenig on 26.09.17.
//

import Foundation

import MapKit
import CoreLocation

extension CLLocationCoordinate2D {
  public var isValid: Bool {
    let suspicious = (abs(latitude) < 0.01 && abs(longitude) < 0.01)
    assert(!suspicious, "Suspicious coordinate: \(self)")
    return CLLocationCoordinate2DIsValid(self) && !suspicious
  }
  
  public func distance(from other: CLLocationCoordinate2D) -> CLLocationDistance? {
    guard isValid && other.isValid else { return nil }
    let me = CLLocation(latitude: latitude, longitude: longitude)
    let you = CLLocation(latitude: other.latitude, longitude: other.longitude)
    return me.distance(from: you)
  }
}

extension MKCoordinateRegion {
  public var topLeft: CLLocationCoordinate2D {
    return validCoordinate(latitude: center.latitude + span.latitudeDelta / 2, longitude: center.longitude - span.longitudeDelta / 2)
  }
  
  public var bottomRight: CLLocationCoordinate2D {
    return validCoordinate(latitude: center.latitude - span.latitudeDelta / 2, longitude: center.longitude + span.longitudeDelta / 2)
  }
  
  private func validCoordinate(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> CLLocationCoordinate2D {
    let lat = max(-90, min(90, latitude))
    var lng = longitude
    while lng < -180 {
      lng += 360
    }
    while lng > 180 {
      lng -= 360
    }
    return CLLocationCoordinate2D(latitude: lat, longitude: lng)
  }
}

extension MKMapRect {
  public static func forCoordinateRegion(_ region: MKCoordinateRegion) -> MKMapRect
  {
    let a = MKMapPointForCoordinate(region.topLeft)
    let b = MKMapPointForCoordinate(region.bottomRight)
    
    return MKMapRectMake(min(a.x,b.x), min(a.y,b.y), abs(a.x-b.x), abs(a.y-b.y))
  }
}

extension Array where Element: MKAnnotation {
  
  public var mapRect: MKMapRect {
    return reduce(MKMapRectNull) { prior, annotation in
      let point = MKMapPointForCoordinate(annotation.coordinate)
      let miniRect = MKMapRect(origin: point, size: MKMapSize(width: 1, height: 1))
      return MKMapRectUnion(prior, miniRect)
    }
  }
  
}
