//
//  TKAddressFormatter.swift
//  TripKit
//
//  Created by Adrian Schönig on 23.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import Contacts

public class TKAddressFormatter: NSObject {
  
  private override init() {
    super.init()
  }
  
  @objc(singleLineAddressStringForPostalAddress:)
  public static func singleLineAddress(for postalAddress: CNPostalAddress) -> String {
    return CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress)
      .replacingOccurrences(of: "\n", with: ", ")
      .replacingOccurrences(of: "  ", with: " ")
  }
  
  @objc(singleLineAddressStringForPlacemark:)
//  @available(iOS, obsoleted: 11.0, message: "Use `CNPostalAddressFormatter.string(from: placemark.postalAddress)` directly instead")
  public static func singleLineAddress(for placemark: CLPlacemark) -> String? {
    let postalAddress: CNPostalAddress
    
    if #available(iOS 11.0, *), let fromPlacemark = placemark.postalAddress {
      postalAddress = fromPlacemark
    } else if let dict = placemark.addressDictionary {
      postalAddress = self.postalAddress(forAddressDictionary: dict)
    } else {
      return nil
    }
    
    return singleLineAddress(for: postalAddress)
  }
  
  private static func postalAddress(forAddressDictionary dict: [AnyHashable: Any]) -> CNPostalAddress {
    let address = CNMutablePostalAddress()
    address.street = dict["Street"] as? String ?? ""
    address.state = dict["State"] as? String ?? ""
    address.city = dict["City"] as? String ?? ""
    address.country = dict["Country"] as? String ?? ""
    address.postalCode = dict["ZIP"] as? String ?? ""
    return address
  }
}
