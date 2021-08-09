//
//  SGDeprecatedGeocoder+TKGeocoding.swift
//  TripKit
//
//  Created by Adrian Schönig on 17.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension SGDeprecatedGeocoder {
  
  public func geocode(_ input: String, near mapRect: MKMapRect, completion: @escaping (Result<[TKNamedCoordinate], Error>) -> Void) {
    
    geocodeString(input, nearRegion: mapRect, success: { _, coordinates in
      completion(.success(coordinates))
    }, failure: { input, error in
      completion(.failure(error ?? TKGeocoderHelper.GeocodingError.serverFoundNoMatch(input)))
    })
  }
  
}

extension TKSkedGoGeocoder: TKGeocoding {}
