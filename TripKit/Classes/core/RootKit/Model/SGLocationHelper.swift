//
//  SGLocationHelper.swift
//  TripKit
//
//  Created by Adrian Schoenig on 13/7/17.
//
//

import Foundation

import Contacts

#if os(iOS)
  import func AddressBookUI.ABCreateStringWithAddressDictionary
#endif

extension SGLocationHelper {
  
  @objc(postalAddressForPlacemark:)
  public static func postalAddress(for placemark: CLPlacemark) -> String? {
    
    guard let dict = placemark.addressDictionary else { return nil }
    
    // TODO: iOS 11 does this better
    let address = postalAddress(forAddressDictionary: dict)
    let oneLine = address.replacingOccurrences(of: "\n", with: ", ")
    return oneLine
  }
  
  @objc(postalAddressForAddressDictionary:)
  public static func postalAddress(forAddressDictionary dict: [AnyHashable: Any]) -> String {
    
    // TODO: iOS 11 does this better
    
    let address = CNMutablePostalAddress()
    address.street = dict["Street"] as? String ?? ""
    address.state = dict["State"] as? String ?? ""
    address.city = dict["City"] as? String ?? ""
    address.country = dict["Country"] as? String ?? ""
    address.postalCode = dict["ZIP"] as? String ?? ""
    
    return CNPostalAddressFormatter.string(from: address, style: .mailingAddress).replacingOccurrences(of: "\n", with: ", ")
  }
  
}
