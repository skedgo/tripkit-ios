//
//  TKRoutePolyline.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/10/16.
//
//

import Foundation
import CoreLocation
import MapKit

// MARK: - TKDisplayableRoute, the input

@objc
public protocol TKDisplayableRoute {
  
  var routePath: [Any] { get } // objects that have a coordinate, e.g., <MKAnnotation> or CLLocation
  var routeColor: TKColor? { get }
  var routeDashPattern: [NSNumber]? { get }
  var routeIsTravelled: Bool { get }
  var selectionIdentifier: String? { get }
  
}

extension TKDisplayableRoute {
  @nonobjc public var routeColor: TKColor? { return nil }
  @nonobjc public var routeDashPattern: [NSNumber]? { return nil }
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
  
  public var routeIsTravelled: Bool {
    return true
  }
  
  public var selectionIdentifier: String? {
    return nil
  }
  
}

public class TKRoutePolyline : MKPolyline {
  public var route: TKDisplayableRoute!
  
  public var selectionIdentifier: String?
  
  public convenience init?(route: TKDisplayableRoute) {
    let pathpoints = route.routePath
    guard !pathpoints.isEmpty else { return nil }
    
    let coordinates = pathpoints.compactMap { obj -> CLLocationCoordinate2D? in
      switch obj {
      case let coordinate as CLLocationCoordinate2D: return coordinate
      case let location as CLLocation: return location.coordinate
      case let annotation as MKAnnotation: return annotation.coordinate
      default: return nil
      }
    }
    
    self.init(coordinates: coordinates, count: coordinates.count)

    self.route = route
  }
  
  
  /// - Returns: A geodesic polyline connecting the annotations
  public static func geodesicPolyline(annotations: [MKAnnotation]) -> MKGeodesicPolyline? {
    guard !annotations.isEmpty else { return nil }
    
    let coordinates = annotations.map(\.coordinate)
    return MKGeodesicPolyline(coordinates: coordinates, count: coordinates.count)
  }
}
