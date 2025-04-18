//
//  TKConfig+TripKit.swift
//  TripKit
//
//  Created by Adrian Schönig on 20/11/2024.
//

import Foundation

// MARK: - Basic app configuration

extension TKConfig {

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
  
  public var betaServerBaseURL: String {
    return configuration["BetaServerBaseURL"] as? String ?? "https://bigbang.buzzhives.com/satapp-beta/"
  }

}

// MARK: - Style

extension TKConfig {

  var globalTintColor: [String: Int]? {
    configuration["GlobalTintColor"] as? [String: Int]
  }
  var globalAccentColor: [String: Int]? {
    configuration["GlobalAccentColor"] as? [String: Int]
  }
  var globalBarTintColor: [String: Int]? {
    configuration["GlobalBarTintColor"] as? [String: Int]
  }
  var globalSecondaryBarTintColor: [String: Int]? {
    configuration["GlobalSecondaryBarTintColor"] as? [String: Int]
  }
  
  var preferredFonts: [String: String]? {
    configuration["PreferredFonts"] as? [String: String]
  }

}
