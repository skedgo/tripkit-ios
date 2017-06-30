//
//  TripRequest+Shareable.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension TripRequest: SGURLShareable {
  
  public var shareURL: URL? {
    return TKShareHelper.createQueryURL(start: fromLocation.coordinate, end: toLocation.coordinate, timeType: type, time: time)
  }
  
}
