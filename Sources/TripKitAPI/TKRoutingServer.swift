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
  private let fixedBaseURL: URL?

  public init(baseURL: URL?, apiKey: String?) {
    assert(baseURL != nil || apiKey != nil)
    self.fixedBaseURL = baseURL
    super.init(isShared: false)
    self.apiKey = apiKey ?? TKServer.shared.apiKey
  }

  public override var baseURL: URL {
    fixedBaseURL ?? super.baseURL
  }
}
