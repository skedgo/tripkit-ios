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
  @objc public var bundleId: String? {
    get { decode(String.self, key: "bundleId") }
    set { encode(newValue, key: "bundleId") }
  }
}
