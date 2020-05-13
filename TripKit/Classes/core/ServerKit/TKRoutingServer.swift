//
//  TKRoutingServer.swift
//  TripKit
//
//  Created by Adrian Schönig on 13.05.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public class TKRoutingServer: TKServer {
  public let baseURL: URL
  
  public init(baseURL: URL) {
    self.baseURL = baseURL
  }
  
  public override func baseURL(for region: TKRegion?, index: UInt) -> URL? {
    guard index == 0 else { return nil }
    return self.baseURL
  }
}
