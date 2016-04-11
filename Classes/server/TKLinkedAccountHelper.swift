//
//  TKLinkedAccountHelper.swift
//  TripGo
//
//  Created by Adrian Schoenig on 8/04/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

struct ProviderAuth {
  
  enum Status {
    case Connected(String, String, NSURL)
    case NotConnected(String, String, NSURL)
    
    var status: String {
      switch self {
      case .Connected(let status, _, _): return status
      case .NotConnected(let status, _, _): return status
      }
    }

    var URL: NSURL {
      switch self {
      case .Connected(_, _, let URL): return URL
      case .NotConnected(_, _, let URL): return URL
      }
    }

    var action: String {
      switch self {
      case .Connected(_, let action, _): return action
      case .NotConnected(_, let action, _): return action
      }
    }
  }

  let modeIdentifier: String
  
  let provider: String
  
  let status: Status
}

extension ProviderAuth.Status {
  private init?(withDictionary dictionary: [String: AnyObject]) {
    guard let action = dictionary["action"] as? String,
          let URLString = dictionary["url"] as? String,
          let actionURL = NSURL(string: URLString),
          let actionTitle = dictionary["actionTitle"] as? String,
          let status = dictionary["status"] as? String else {
      return nil
    }
    
    switch action {
    case "signin":
      self = .NotConnected(status, actionTitle, actionURL)
    case "signout":
      self = .Connected(status, actionTitle, actionURL)
    default:
      return nil
    }
  }
}

extension ProviderAuth {
  private init?(withDictionary dictionary: [String: AnyObject]) {
    guard let mode = dictionary["modeIdentifier"] as? String,
          let provider = dictionary["provider"] as? String,
          let status = Status.init(withDictionary: dictionary) else {
      return nil
    }
    
    self.modeIdentifier = mode
    self.provider = provider
    self.status = status
  }
}

extension SVKRegion {
  func linkedAccounts(mode: String? = nil, completion: [ProviderAuth]? -> Void) {
    
    let paras: [String: AnyObject]?
    if let mode = mode {
      paras = ["mode": mode]
    } else {
      paras = nil
    }
    
    SVKServer.sharedInstance().initiateDataTaskWithMethod(
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