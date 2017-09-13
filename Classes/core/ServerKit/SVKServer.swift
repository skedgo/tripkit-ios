//
//  SVKServer.swift
//  TripKit
//
//  Created by Adrian Schoenig on 20/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension SVKServer {
  
  public static let shared = SVKServer.__sharedInstance()
  
  @objc public class var serverType: SVKServerType {
    get {
      if SGKBetaHelper.isBeta() {
        return SVKServerType(rawValue:  UserDefaults.shared.integer(forKey: SVKDefaultsKeyServerType)) ?? .production
      } else {
        return .production
      }
    }
    set {
      UserDefaults.shared.set(newValue.rawValue, forKey: SVKDefaultsKeyServerType)
    }
  }
  
}
