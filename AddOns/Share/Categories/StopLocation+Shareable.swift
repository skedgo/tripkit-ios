//
//  StopLocation+Shareable.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

#if TK_NO_FRAMEWORKS
#else
  import TripKit
#endif

extension StopLocation: TKURLShareable {
  
  public var shareURL: URL? {
    guard let regionName = region?.name else { return nil }
    return TKShareHelper.createStopURL(stopCode: stopCode, inRegionNamed: regionName, filter: filter)
  }
  
}
