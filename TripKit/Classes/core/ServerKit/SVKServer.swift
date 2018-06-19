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
  
  private static var _serverType: SVKServerType?
  
  @objc public class var serverType: SVKServerType {
    get {
      if let serverType = _serverType {
        return serverType
      } else if SGKBetaHelper.isBeta() {
        _serverType = SVKServerType(rawValue:  UserDefaults.shared.integer(forKey: SVKDefaultsKeyServerType)) ?? .production
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
      UserDefaults.shared.set(newValue.rawValue, forKey: SVKDefaultsKeyServerType)
    }
  }
  
}
