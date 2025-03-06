//
//  TKConfig.swift
//  TripKit
//
//  Created by Adrian Schoenig on 20/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

public class TKConfig {
  
  public static let shared = TKConfig()
  
  private init() {
#if os(Linux)
    configuration = [:]
#else
    // Yes, main!
    if let path = Bundle.main.url(forResource: "Config", withExtension: "plist"), let config = NSDictionary(contentsOf: path) as? [String: AnyHashable] {
      configuration = config
    } else {
      configuration = [:]
    }
#endif
  }
  
  public let configuration: [String: AnyHashable]
  
}

extension TKConfig {
  public var appGroupName: String? {
    configuration["AppGroupName"] as? String
  }
}
