//
//  TKInterAppHelpers.swift
//  TripGo
//
//  Created by Adrian Schoenig on 4/03/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import class CoreLocation.CLGeocoder
import func AddressBookUI.ABCreateStringWithAddressDictionary

extension CLGeocoder {
  public func reverseGeocodeAddress(forCoordinate coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> ()) {
    
    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    reverseGeocodeLocation(location) { placemarks, error in
      guard let placemarks = placemarks else {
        completion(nil)
        return
      }
      
      for placemark in placemarks {
        if let addressDictionary = placemark.addressDictionary {
          // TODO: This is available in Contacts on iOS 11
          let address = ABCreateStringWithAddressDictionary(addressDictionary, true)
          let oneLine = address.replacingOccurrences(of: "\n", with: ", ")
          completion(oneLine)
          return
        }
      }
    }
  }
}
