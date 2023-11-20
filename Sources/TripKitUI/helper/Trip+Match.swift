//
//  Trip+Match.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 20/11/2023.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import TripKit

extension Trip {
  func matches(_ other: Trip) -> Bool {
    if tripURL == other.tripURL {
      return true
    } else if let myID = tripId {
      return other.tripId == myID
    } else {
      return false
    }
  }
}
