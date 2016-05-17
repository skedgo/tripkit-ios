//
//  TKLinkedAccountHelper.swift
//  TripGo
//
//  Created by Adrian Schoenig on 8/04/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public struct ProviderAuth {

  struct RemoteAction {
    let title: String
    let URL: NSURL
  }

  enum Status {
    case Connected(RemoteAction?)
    case NotConnected(RemoteAction)
    
    var remoteURL: NSURL? {
      switch self {
      case .Connected(let action): return action?.URL
      case .NotConnected(let action): return action.URL
      }
    }

    var remoteAction: String? {
      switch self {
      case .Connected(let action): return action?.title
      case .NotConnected(let action): return action.title
      }
    }
  }

  let modeIdentifier: String
  
  let status: Status

  let provider: String?
  
  var action: String {
    if let remoteAction = status.remoteAction {
      return remoteAction
    }
    
    switch status {
    case .Connected: return "Disconnect"
    case .NotConnected: return "Setup"
    }
  }
  
  var isConnected: Bool {
    switch status {
    case .Connected: return true
    case .NotConnected: return false
    }
  }
}

extension ProviderAuth.Status {
  private init?(withDictionary dictionary: [String: AnyObject]) {
    guard let action = dictionary["action"] as? String,
          let actionTitle = dictionary["actionTitle"] as? String,
          let URLString = dictionary["url"] as? String,
          let actionURL = NSURL(string: URLString)
      else {
      return nil
    }
    
    let remoteAction = ProviderAuth.RemoteAction(title: actionTitle, URL: actionURL)
    
    switch action {
    case "signin":
      self = .NotConnected(remoteAction)
    case "logout":
      self = .Connected(remoteAction)
    default:
      return nil
    }
  }
}

extension ProviderAuth {
  private init?(withDictionary dictionary: [String: AnyObject]) {
    guard let mode = dictionary["modeIdentifier"] as? String,
          let status = Status.init(withDictionary: dictionary) else {
      return nil
    }
    
    self.modeIdentifier = mode
    self.status = status
    self.provider = dictionary["provider"] as? String
  }
}

extension SVKRegion {
  /**
   Fetches authentications for the provided mode.
   
   Authentications can be locally stored (requiring no logins) or associated with the user's account and stored server-side. This method first tries locally and then falls back to remotely.
   
   - param mode: Mode identifier for which to fetch accounts. If `nil` accounts for all modes will be fetched.
   - param completion: Block executed on completion with list of accounts that can be linked
  */
  public func linkedAccounts(mode: String? = nil, completion: [ProviderAuth]? -> Void) {
    if let mode = mode, account = locallyLinkedAccount(mode) {
      completion([account])
    } else {
      remotelyLinkedAccounts(mode, completion: completion)
    }
  }
  
  public func unlinkAccount(mode: String, remoteURL: NSURL?, completion: Bool -> Void) {
    let localRemoved = OAuthClient.removeCredentials(provider: mode)
    
    guard let URL = remoteURL else {
      completion(localRemoved)
      return
    }
    
    // Also unlink remote
    SVKServer.GET(URL, paras: nil) { response, error in
      if let response = response as? [NSObject: AnyObject]
        where response.isEmpty && error == nil {
        completion(true && localRemoved)
      } else {
        completion(false)
      }
    }
    
  }

  private func locallyLinkedAccount(mode: String) -> ProviderAuth? {
    if let cached = OAuthClient.cachedCredentials(provider: mode) {
      if (cached.isValid || cached.hasRefreshToken) {
        let status = ProviderAuth.Status.Connected(nil)
        return ProviderAuth(modeIdentifier: mode, status: status, provider: nil)
      } else {
        // Remove outdated credentials that we can't renew
        OAuthClient.removeCredentials(provider: mode)
      }
    }
    return nil;
  }
  
  private func remotelyLinkedAccounts(mode: String?, completion: [ProviderAuth]? -> Void) {
    
    let paras: [String: AnyObject]?
    if let mode = mode {
      paras = ["mode": mode]
    } else {
      paras = nil
    }
    
    SVKServer.sharedInstance().hitSkedGoWithMethod(
      "GET",
      path: "auth/\(name)",
      parameters: paras,
      region: self,
      success: { response in
        guard let array = response as? [[String: AnyObject]] where !array.isEmpty else {
          completion([])
          return
        }
        
        completion( array.flatMap { ProviderAuth(withDictionary: $0) } )
      }, failure: { error in
        completion(nil)
      }
    )
  }
}