//
//  TKConfig.swift
//  TripKit
//
//  Created by Adrian Schoenig on 20/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension TKConfig {
  
  public static let shared = TKConfig.__sharedInstance()
  
}

// MARK: - Basic app configuration

extension TKConfig {

  @objc
  public var appGroupName: String? {
    return configuration["AppGroupName"] as? String
  }

  @objc
  public var appURLScheme: String? {
    return configuration["URLScheme"] as? String
  }
  
  public var oauthCallbackURL: URL? {
    guard let urlString = configuration["OAuthCallbackURL"] as? String else { return nil }
    return URL(string: urlString)
  }

  /// URL (including scheme and domain) used when constructing share URLs
  ///
  /// - Note: If this is not set, then sharing within the apps should generally
  ///     be disabled. You'll still get, say, a `shareURL` for a trip, but
  ///     then will point at https://tripgo.com.
  public var shareURLDomain: String? {
    return configuration["ShareURLDomain"] as? String
  }

}
