//
//  TKUberSSO.swift
//  TripKit
//
//  Created by Adrian Schoenig on 7/10/16.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation



fileprivate struct SSOResult : OAuthData {
  let accessToken: String?
  let expiration: TimeInterval?
  let refreshToken: String?
  let grantedScopes: [String]
}

public enum TKUberSSOError : Error {
  
  case errorFromUber(String)
  
}

/// Implements Single-Sign-On for Uber. 
/// Based on V0.5.2 of [Uber's iOS SDK](https://github.com/uber/rides-ios-sdk).
public enum TKUberSSO : SSOCompatible {
  
  public static var mode: String { return "ps_tnc_UBER" }
  
  public static var pretendUberIsInstalled = false
  
  public static func canHandle(mode: String) -> Bool {
    guard mode.lowercased().contains("uber") else { return false }

    var components = URLComponents()
    components.scheme = "uberauth"
    components.host   = "connect"
    guard let url = components.url else {
      preconditionFailure()
    }
    
    // Is Uber installed?
    return pretendUberIsInstalled || UIApplication.shared.canOpenURL(url)
  }
  
  public static var identifier = "uber"
  
  public static func start() {
    guard !pretendUberIsInstalled else { return }
    
    let urlScheme = SGKConfig.shared.appURLScheme()
    let appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "TripGo"
    
    var components = URLComponents()
    components.scheme = "uberauth"
    components.host   = "connect"
    components.queryItems = [
      URLQueryItem(name: "third_party_app_name",  value: appName),
      URLQueryItem(name: "callback_uri_string",   value: urlScheme + "://sso-uber"),
      URLQueryItem(name: "client_id",             value: "hBzl1hd9ihxKNnB7baQdp8y8iImTOfOF"),
      URLQueryItem(name: "login_type",            value: "default"),
      URLQueryItem(name: "scope",                 value: "request"),
      URLQueryItem(name: "sdk",                   value: "ios"),
      URLQueryItem(name: "sdk_version",           value: "0.5.2"),
    ]
    
    guard
      let url = components.url,
      UIApplication.shared.canOpenURL(url)
      else {
        preconditionFailure("You shouldn't call `start` if `canHandle(mode:)` returns false")
    }
    
    if #available(iOS 10.0, *) {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    } else {
      UIApplication.shared.openURL(url)
    }
  }
  
  public static func handle(_ url: URL) throws -> OAuthData? {
    guard let input = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      return nil
    }
    
    var components = input
    var finalQueryArray = [String]()
    if let existingQuery = components.query {
      finalQueryArray.append(existingQuery)
    }
    if let existingFragment = components.fragment {
      finalQueryArray.append(existingFragment)
    }
    components.fragment = nil
    components.query = finalQueryArray.joined(separator: "&")
    
    guard let queryItems = components.queryItems else {
      return nil
    }
    var query = [String : String]()
    for item in queryItems {
      guard let value = item.value else {
        continue
      }
      query[item.name] = value
    }
    if let error = query["error"] {
      SGKLog.warn("TKUberSSO", text: "Error: \(error)")
      throw TKUberSSOError.errorFromUber(error)
    }

    guard let accessToken = query["access_token"] else {
      return nil
    }
    
    var expiration: TimeInterval? = nil
    if let raw = query["expires_in"], let seconds = TimeInterval(raw) {
      expiration = seconds
    }
    
    return SSOResult(
      accessToken: accessToken,
      expiration: expiration,
      refreshToken: query["refresh_token"],
      grantedScopes: query["scope"]?.components(separatedBy: " ") ?? []
    )
  }
  
}
