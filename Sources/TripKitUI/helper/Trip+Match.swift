//
//  Trip+Match.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 20/11/2023.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import TripKit

extension Trip {
  func matches(tripURL: URL, tripID: String?) -> Bool {
    if self.tripURL == tripURL {
      return true
    } else if let myID = self.tripId {
      return myID == tripID
    } else {
      return false
    }
  }
}
