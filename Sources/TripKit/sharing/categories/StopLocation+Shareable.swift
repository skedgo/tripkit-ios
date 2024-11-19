//
//  StopLocation+Shareable.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

#if canImport(CoreData)

import Foundation

extension StopLocation: TKURLShareable {
  
  public var shareURL: URL? {
    guard let code = region?.code else { return nil }
    return TKShareHelper.createStopURL(stopCode: stopCode, regionCode: code, filter: filter)
  }
  
}

#endif
