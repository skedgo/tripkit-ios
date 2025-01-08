//
//  TKAddressFormatter.swift
//  TripKit
//
//  Created by Adrian Schönig on 23.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

#if canImport(Contacts)

import Foundation
import Contacts
import CoreLocation

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
  public static func singleLineAddress(for placemark: CLPlacemark) -> String? {
    guard let postalAddress = placemark.postalAddress else { return nil }
    return singleLineAddress(for: postalAddress)
  }
}

#endif
