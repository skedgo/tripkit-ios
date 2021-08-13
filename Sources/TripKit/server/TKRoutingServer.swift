//
//  TKRoutingServer.swift
//  TripKit
//
//  Created by Adrian Schönig on 13.05.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

#if SWIFT_PACKAGE
import TripKitObjc
#endif

/**
 `TKServer` subclass that is forced to hit the provided `baseURL` for SkedGo calls.
 */
public class TKRoutingServer: TKServer {
  private let baseURL: URL
  
  public init(baseURL: URL) {
    self.baseURL = baseURL
  }
  
  public override func baseURLs(for region: TKRegion?) -> [URL] {
    [baseURL]
  }
}
