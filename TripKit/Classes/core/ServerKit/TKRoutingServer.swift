//
//  TKRoutingServer.swift
//  TripKit
//
//  Created by Adrian Schönig on 13.05.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

/**
 `TKServer` subclass that is forced to hit the provided `baseURL` for SkedGo calls.
 */
public class TKRoutingServer: TKServer {
  private let baseURL: URL
  
  public init(baseURL: URL) {
    self.baseURL = baseURL
  }
  
  public override func _baseURL(for region: TKRegion?, index: UInt) -> URL? {
    guard index == 0 else { return nil }
    return self.baseURL
  }
}
