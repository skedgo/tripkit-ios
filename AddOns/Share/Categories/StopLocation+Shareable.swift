//
//  StopLocation+Shareable.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension StopLocation: SGURLShareable {
  
  public var shareURL: URL? {
    guard let regionName = region?.name else { return nil }
    return TKShareHelper.stopURL(forStopCode: stopCode, inRegionNamed: regionName, filter: filter)
  }
  
}
