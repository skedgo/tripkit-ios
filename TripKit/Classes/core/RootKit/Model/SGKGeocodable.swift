//
//  SGKGeocodable.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 25/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation
import CoreLocation

@objc
public protocol SGKGeocodable {
  var addressForGeocoding: String? { get }
  var needsForwardGeocoding: Bool { get }
  var didAttemptGeocodingBefore: Bool { get set }
  func assign(_ coordinate: CLLocationCoordinate2D, forAddress: String)
}
