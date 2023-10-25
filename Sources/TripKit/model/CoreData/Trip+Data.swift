//
//  Trip+Data.swift
//  TripKit
//
//  Created by Adrian Schönig on 14.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension Trip: DataAttachable {}

extension Trip {
  public var bundleId: String? {
    get { decodePrimitive(String.self, key: "bundleId") }
    set { encodePrimitive(newValue, key: "bundleId") }
  }
  
  /// Unique ID of the trip, which may change if the trip is saved in permanent storage (although it is unlikely).
  public var tripId: String? {
    get { decodePrimitive(String.self, key: "tripId") }
    set { encodePrimitive(newValue, key: "tripId") }
  }
  
  public var subscribeURL: URL? {
    get { decodePrimitive(String.self, key: "subscribeURL").flatMap { URL(string: $0) } }
    set { encodePrimitive(newValue?.absoluteString, key: "subscribeURL") }
  }
  
  public var unsubscribeURL: URL? {
    get { decodePrimitive(String.self, key: "unsubscribeURL").flatMap { URL(string: $0) } }
    set { encodePrimitive(newValue?.absoluteString, key: "unsubscribeURL") }
  }
}
