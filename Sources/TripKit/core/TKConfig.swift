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

  public var appGroupName: String? {
    configuration["AppGroupName"] as? String
  }
  
  @objc
  public var appURLScheme: String? {
    return configuration["URLScheme"] as? String
  }
  
  public var oauthCallbackURL: URL? {
    guard let urlString = configuration["OAuthCallbackURL"] as? String else { return nil }
    return URL(string: urlString)
  }
  
  public var attributionRequired: Bool {
    return configuration["AttributionRequired"] as? Bool ?? true
  }

  /// URL (including scheme and domain) used when constructing share URLs
  ///
  /// - Note: If this is not set, then sharing within the apps should generally
  ///     be disabled. You'll still get, say, a `shareURL` for a trip, but
  ///     then will point at https://tripgo.com.
  public var shareURLDomain: String? {
    return configuration["ShareURLDomain"] as? String
  }
  
  /// Base URL used to connect to our beta server. This allows WLs to point
  /// to a temporary deployment of satapp.
  ///
  /// - Note: If this is not set, then the default base URL,
  ///  "https://bigbang.buzzhives.com/satapp-beta/" is used.
  
  @objc
  public var betaServerBaseURL: String {
    return configuration["BetaServerBaseURL"] as? String ?? "https://bigbang.buzzhives.com/satapp-beta/"
  }

}
