//
//  StopVisits+Shareable.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

#if TK_NO_MODULE
#else
  import TripKit
#endif

extension StopVisits: TKURLShareable {
  
  public var shareURL: URL? {
    guard let regionName = stop.region?.name else { return nil }
    return TKShareHelper.createServiceURL(serviceID: service.code, atStopCode: stop.stopCode, inRegionNamed: regionName)
  }
  
}
