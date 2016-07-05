//
//  TKInterAppHelpers.swift
//  TripGo
//
//  Created by Adrian Schoenig on 4/03/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import class CoreLocation.CLGeocoder
//import class Contacts.CNPostalAddressFormatter
import func AddressBookUI.ABCreateStringWithAddressDictionary

extension CLGeocoder {
  public func reverseGeocodeAddress(forCoordinate coordinate: CLLocationCoordinate2D, completion: (NSString?) -> ()) {
    
    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    reverseGeocodeLocation(location) { placemarks, error in
      guard let placemarks = placemarks else {
        completion(nil)
        return
      }
      
      for placemark in placemarks {
        if let addressDictionary = placemark.addressDictionary {
          let address = ABCreateStringWithAddressDictionary(addressDictionary, true)
          let oneLine = address.stringByReplacingOccurrencesOfString("\n", withString: ", ")
          completion(oneLine)
          return
        }
      }
    }
  }
}