//
//  StopVisits+Shareable.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension StopVisits: TKURLShareable {
  
  public var shareURL: URL? {
    guard let regionName = stop.region?.code else { return nil }
    return TKShareHelper.createServiceURL(serviceID: service.code, stopCode: stop.stopCode, regionCode: regionName)
  }
  
}
