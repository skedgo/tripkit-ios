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
    let address: String
    
    if #available(iOS 9.0, macOS 10.11, *) {
      address = postalAddress(forAddressDictionary: dict)
    } else {
      #if os(iOS)
        address = ABCreateStringWithAddressDictionary(dict, true)
      #else
        return nil
      #endif
    }
    
    let oneLine = address.replacingOccurrences(of: "\n", with: ", ")
    return oneLine
  }
  
  @available(iOS 9.0, macOS 10.11, *)
  @objc(postalAddressForAddressDictionary:)
  public static func postalAddress(forAddressDictionary dict: [AnyHashable: Any]) -> String {
    
    // TODO: iOS 11 does this better
    
    let address = CNMutablePostalAddress()
    address.street = dict["Street"] as? String ?? ""
    address.state = dict["State"] as? String ?? ""
    address.city = dict["City"] as? String ?? ""
    address.country = dict["Country"] as? String ?? ""
    address.postalCode = dict["ZIP"] as? String ?? ""
    
    return CNPostalAddressFormatter.string(from: address, style: .mailingAddress)
  }
  
}
