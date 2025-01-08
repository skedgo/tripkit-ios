//
//  Trip+Data.swift
//  TripKit
//
//  Created by Adrian Schönig on 14.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

#if canImport(CoreData)

import Foundation

extension Trip: DataAttachable {}

extension Trip {
  /// Additional information when a trip is not available, e.g., due to missing the booking window or
  /// it being cancelled. This is localised and meant to be user-facing.
  public var availabilityInfo: String? {
    get { decodePrimitive(String.self, key: "availabilityInfo") }
    set { encodePrimitive(newValue, key: "availabilityInfo") }
  }

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

#endif