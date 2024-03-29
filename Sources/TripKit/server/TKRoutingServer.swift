//
//  TKRoutingServer.swift
//  TripKit
//
//  Created by Adrian Schönig on 13.05.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

/**
 `TKServer` subclass that is forced to hit the provided `baseURL` and API key for SkedGo calls.
 */
public class TKRoutingServer: TKServer {
  let baseURL: URL?
  
  public init(baseURL: URL?, apiKey: String?) {
    assert(baseURL != nil || apiKey != nil)
    self.baseURL = baseURL
    super.init(isShared: false)
    self.apiKey = apiKey ?? TKServer.shared.apiKey
  }
  
  public override func baseURLs(for region: TKRegion?) -> [URL] {
    if let fixed = baseURL {
      return [fixed]
    } else {
      return super.baseURLs(for: region)
    }
  }
}
