//
//  SGDeprecatedGeocoder+TKGeocoding.swift
//  TripKit
//
//  Created by Adrian Schönig on 17.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

extension SGDeprecatedGeocoder {
  
  public func geocode(_ input: String, near mapRect: MKMapRect) -> Single<[TKNamedCoordinate]> {
    
    return Single.create { subscriber in
      self.geocodeString(input, nearRegion: mapRect, success: { _, coordinates in
        subscriber(.success(coordinates))
      }, failure: { input, error in
        subscriber(.error(error ?? TKGeocoderHelper.GeocodingError.serverFoundNoMatch(input)))
      })
      return Disposables.create()
    }
    
  }
  
}

extension TKFoursquareGeocoder: TKGeocoding {}
extension TKSkedGoGeocoder: TKGeocoding {}
