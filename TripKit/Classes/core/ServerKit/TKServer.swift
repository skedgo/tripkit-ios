//
//  TKServer.swift
//  TripKit
//
//  Created by Adrian Schoenig on 20/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension TKServer {
  
  public static let shared = TKServer.__sharedInstance()
  
  private static var _serverType: TKServerType?
  
  @objc public class var serverType: TKServerType {
    get {
      if let serverType = _serverType {
        return serverType
      } else if TKBetaHelper.isBeta() {
        _serverType = TKServerType(rawValue:  UserDefaults.shared.integer(forKey: TKDefaultsKeyServerType)) ?? .production
        return _serverType!
      } else {
        _serverType = .production
        return _serverType!
      }
    }
    set {
      // Only do work, if necessary, to not trigger unnecessary calls
      guard newValue != _serverType else { return }
      _serverType = newValue
      UserDefaults.shared.set(newValue.rawValue, forKey: TKDefaultsKeyServerType)
    }
  }
  
}
