//
//  TKRoutePolyline.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/10/16.
//
//

import Foundation
import CoreLocation

@objc
public protocol TKDisplayableRoute {
  
  var routePath: [Any] { get }// objects that have a coordinate, e.g., <MKAnnotation> or CLLocation
  var routeColor: TKColor? { get }
  var routeDashPattern: [NSNumber]? { get }
  var showRoute: Bool { get }
  var routeIsTravelled: Bool { get }
  
}

extension TKDisplayableRoute {
  @nonobjc public var routeColor: TKColor? { return nil }
  @nonobjc public var routeDashPattern: [NSNumber]? { return nil }
  @nonobjc public var showRoute: Bool { return true }
  @nonobjc public var routeIsTravelled: Bool { return true }
}



fileprivate class WrappedCoordinate {
  fileprivate let coordinate: CLLocationCoordinate2D
  init(_ coordinate: CLLocationCoordinate2D) {
    self.coordinate = coordinate
  }
}

extension MKGeodesicPolyline : TKDisplayableRoute {
  public var routePath: [Any] {
    var coordinates = [CLLocationCoordinate2D]()
    coordinates.reserveCapacity(pointCount)
    getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
    return coordinates.map { WrappedCoordinate($0) }
  }
  
  public var routeColor: TKColor? {
    return nil
  }
  
  public var routeDashPattern: [NSNumber]? {
    return nil
  }
  
  public var showRoute: Bool {
    return true
  }
  
  public var routeIsTravelled: Bool {
    return true
  }
  
}

@available(*, unavailable, renamed: "TKDisplayableRoute")
public typealias STKDisplayableRoute = TKDisplayableRoute

