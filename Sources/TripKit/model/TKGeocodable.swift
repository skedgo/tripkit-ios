//
//  TKGeocodable.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 25/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

#if canImport(CoreLocation)
import Foundation
import CoreLocation

@objc
public protocol TKGeocodable {
  var addressForGeocoding: String? { get }
  var needsForwardGeocoding: Bool { get }
  func assign(_ coordinate: CLLocationCoordinate2D, forAddress: String)
}

@available(*, unavailable, renamed: "TKGeocodable")
public typealias SGKGeocodable = TKGeocodable

#endif