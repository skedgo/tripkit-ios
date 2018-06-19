//
//  OAuthStatus.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 21/03/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public protocol OAuthData {
  var accessToken: String? { get }
  var refreshToken: String? { get }
  var expiration: TimeInterval? { get }
  var expirationDate: Date? { get }
}

public extension OAuthData {
  var expirationDate: Date? { return nil }
  
  var isValid: Bool {
    if let expirationDate = expirationDate {
      return expirationDate.timeIntervalSinceNow > 0
    } else {
      return true // No expiration date: always good
    }
  }
  
  var hasRefreshToken: Bool {
    return refreshToken != nil
  }
}

class PersistentOAuthData: NSObject, OAuthData, NSSecureCoding {
  
  let accessToken: String?
  let refreshToken: String?
  let expiration: TimeInterval?
  let expirationDate: Date?
  
  init(_ oauth: OAuthData) {
    accessToken = oauth.accessToken
    refreshToken = oauth.refreshToken
    expiration = oauth.expiration
    expirationDate = oauth.expirationDate
    super.init()
  }
  
  static var supportsSecureCoding: Bool { return true }
  
  required init?(coder aDecoder: NSCoder) {
    accessToken = aDecoder.decodeObject(forKey: "accessToken") as? String
    refreshToken = aDecoder.decodeObject(forKey: "refreshToken") as? String
    expiration = aDecoder.decodeObject(forKey: "expiration") as? TimeInterval
    
    if let expiration1970 = aDecoder.decodeObject(forKey: "expirationDate") as? TimeInterval {
      expirationDate = Date(timeIntervalSince1970: expiration1970)
    } else {
      expirationDate = nil
    }
    super.init()
  }
  
  func encode(with aCoder: NSCoder) {
    aCoder.encode(accessToken, forKey: "accessToken")
    aCoder.encode(refreshToken, forKey: "refreshToken")
    aCoder.encode(expiration, forKey: "expiration")
    aCoder.encode(expirationDate?.timeIntervalSince1970, forKey: "expirationDate")
  }
  
}

struct RawOAuthData: OAuthData {
  
  init(_ rawData: [String: Any]) {
    self.rawData = rawData
  }
  
  let rawData: [String: Any]
  
  var accessToken: String? {
    return rawData["access_token"] as? String
  }
  
  var refreshToken: String? {
    if let token = rawData["refresh_token"] as? String, !token.isEmpty {
      return token
    } else {
      return nil
    }
  }
  
  var expiration: TimeInterval? {
    if let int = rawData["expires_in"] as? Int {
      return TimeInterval(int)
    
    } else if let string = rawData["expires_in"] as? String {
      return TimeInterval(string)
    
    } else {
      return nil
    }
  }
  
  var expirationDate: Date? {
    guard
      let string = rawData["expirationSince1970"] as? String,
      let expirationSince1970 = TimeInterval(string)
      else {
        return nil
    }
    
    return Date(timeIntervalSince1970: expirationSince1970)
  }
}

public struct OAuthParameter {
  /// Name of the provider to authenticate with, e.g., "Twitter", "Uber"
  let provider: String
  
  /// The client ID that we get from the provider
  let clientID: String
  
  /// The client secret that we get from the provider
  let clientSecret: String
  
  /// The authentication URL used by OAuth,
  /// e.g., "https://login.uber.com/oauth/v2/authorize"
  let oauthURL: String
  
  /// The URL that is used to get OAuth tokens.
  /// e.g., "https://login.uber.com/oauth/v2/token"
  let tokenURL: String
  
  /// The scope parameter is typicall provided by the provider.
  /// This parameter is used to limit the access to user data.
  let scope: String
  
  /// The response type parameter provided by the provider.
  /// Uber and Lyft currently only supports "code" reponse.
  let responseType = "code"
  
  /// This is the URL that we use to POST OAuth credentials,
  /// e.g., access & refresh tokens + expiration time to
  /// SkedGo server.
  let postURL: URL?
  
  /// Whether the step to get the access token uses basic
  /// authentication to send along the client ID + scret.
  let accessTokenBasicAuth: Bool
}
