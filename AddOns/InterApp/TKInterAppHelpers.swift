//
//  TKInterAppHelpers.swift
//  TripGo
//
//  Created by Adrian Schoenig on 4/03/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

#if TK_NO_FRAMEWORKS
#else
  import TripKit
#endif


import class CoreLocation.CLGeocoder

extension CLGeocoder {
  public func reverseGeocodeAddress(forCoordinate coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> ()) {
    
    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    reverseGeocodeLocation(location) { placemarks, error in
      guard let placemarks = placemarks else {
        completion(nil)
        return
      }
      
      for placemark in placemarks {
        if let postalAddress = SGLocationHelper.postalAddress(for: placemark) {
          completion(postalAddress)
          return
        }
      }
    }
  }
}
