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
}
