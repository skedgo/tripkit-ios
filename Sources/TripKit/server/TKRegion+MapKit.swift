//
//  TKRegion+MapKit.swift
//  TripKit
//
//  Created by Adrian Schoenig on 3/1/17.
//
//

import Foundation

import CoreLocation
import MapKit

extension TKRegion {

  @objc(containsCoordinate:)
  public func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
    return contains(latitude: coordinate.latitude, longitude: coordinate.longitude)
  }
  
  @objc(intersectsMapRect:)
  public func intersects(_ mapRect: MKMapRect) -> Bool {
    // Fast check, based on bounding boxes
    guard polygon.intersects(mapRect) else { return false }
    
    let points = [
        MKMapPoint(x: mapRect.minX, y: mapRect.minY),
        MKMapPoint(x: mapRect.minX, y: mapRect.maxY),
        MKMapPoint(x: mapRect.maxX, y: mapRect.maxY),
        MKMapPoint(x: mapRect.maxX, y: mapRect.minY),
      ]
      .map(\.coordinate)
      .map { (latitude: $0.latitude, longitude: $0.longitude) }
  
    return intersects(polygonPoints: points)
  }

}

extension TKRegion.City {
  public convenience init(title: String, coordinate: CLLocationCoordinate2D) {
    self.init(
      title: title,
      latitude: coordinate.latitude,
      longitude: coordinate.longitude
    )
  }

  public var centerBiasedMapRect: MKMapRect {
    // centre it on the region's coordinate
    let size = MKMapSize(width: 300_000, height: 400_00)
    var center = MKMapPoint(coordinate)
    center.x -= size.width / 2
    center.y -= size.height / 2
    return MKMapRect(origin: center, size: size)
  }
}

extension TKRegion.City: MKAnnotation {
  public var coordinate: CLLocationCoordinate2D {
    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
  
  public var title: String? { name }
  
  // This shouldn't be necessary, but there were reports of crashes when
  // calling `[MKMapView removeAnnotations:]`:
  //
  //      Terminating app due to uncaught exception 'NSUnknownKeyException',
  //      reason: '[<TKRegionCity 0x7f957975d000> valueForUndefinedKey:]: this
  //      class is not key value coding-compliant for the key subtitle.'
  public var subtitle: String? { nil }
}

extension TKRegion {
  static var international: TKInternationalRegion { .shared }
}

public class TKInternationalRegion : TKRegion {
  
  public static let shared = TKInternationalRegion()
  
  fileprivate init() {
    let modes: [TKTransportMode] = [
      .flight,
      .publicTransport,
      .car,
      .motorbike,
    ]
    super.init(asInternationalWithCode: "International", modes: modes.map(\.modeIdentifier))
  }
  
  public required init(from decoder: Decoder) throws {
    throw TKRegionParserError.cannotParseInternationalRegion
  }
  
  override public func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
    return coordinate.isValid
  }
}

@available(*, unavailable, renamed: "TKRegion")
public typealias SVKRegion = TKRegion

@available(*, unavailable, renamed: "TKInternationalRegion")
public typealias SVKInternationalRegion = TKInternationalRegion
