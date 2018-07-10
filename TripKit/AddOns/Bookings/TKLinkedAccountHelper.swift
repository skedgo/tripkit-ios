//
//  TKLinkedAccountHelper.swift
//  TripKit
//
//  Created by Adrian Schoenig on 8/04/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

public struct ProviderAuth: Decodable {
  
  private enum DecodingError: Error {
    case unknownAction(String)
  }

  struct RemoteAction {
    let title: String
    let url: URL
  }

  enum Status {
    case connected(RemoteAction?)
    case notConnected(RemoteAction)
    
    var remoteURL: URL? {
      switch self {
      case .connected(let action):    return action?.url
      case .notConnected(let action): return action.url
      }
    }

    var remoteAction: String? {
      switch self {
      case .connected(let action):    return action?.title
      case .notConnected(let action): return action.title
      }
    }
  }

  let status: Status
  
  let companyInfo: API.CompanyInfo?
  
  /// Mode identifier that this authentication is for
  public let modeIdentifier: String
  
  /// Name of the company that provides that auth.
  public var name: String? {
    return companyInfo?.name
  }
  
  /// URL that points to the "About" page of the provider.
  public var aboutURL: URL? {
    return companyInfo?.website
  }
  
  /// Current authentication status
  public var isConnected: Bool {
    switch status {
    case .connected:    return true
    case .notConnected: return false
    }
  }

  /// Title  for button to change authentication status
  public var action: String {
    if let remoteAction = status.remoteAction {
      return remoteAction
    }
    
    // Normally, the action title comes from our backend.
    switch status {
    case .connected:    return Loc.Disconnect
    case .notConnected: return Loc.Setup
    }
  }
  
  /// Optional URL to either link or unlink the account. 
  /// Only available if user has an account.
  public var actionURL: URL? {
    return status.remoteURL
  }
  
  // MARK: Decodable
  
  private enum CodingKeys: String, CodingKey {
    // These go into status
    case action
    
    // These go into status' actions
    case actionTitle
    case url
    
    // These go into the top level
    case modeIdentifier
    case companyInfo
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    let actionTitle = try container.decode(String.self, forKey: .actionTitle)
    let actionUrl = try container.decode(URL.self, forKey: .url)
    let remoteAction = RemoteAction(title: actionTitle, url: actionUrl)
    
    let action = try container.decode(String.self, forKey: .action)
    switch action {
    case "signin": status = .notConnected(remoteAction)
    case "logout": status = .connected(remoteAction)
    default: throw DecodingError.unknownAction(action)
    }
    
    modeIdentifier = try container.decode(String.self, forKey: .modeIdentifier)
    companyInfo = try? container.decode(API.CompanyInfo.self, forKey: .companyInfo)
  }
  
}

extension TKRegion {
  /**
   Fetches authentications for the provided `mode`.
   
   Authentications are associated with the user's account and stored server-side.
   
   - parameter mode: Mode identifier for which to fetch accounts. If `nil`, accounts for all modes will be fetched.
   - parameter completion: Block executed on completion with list of accounts that can be linked.
  */
  public func linkedAccounts(_ mode: String? = nil, completion: @escaping ([ProviderAuth]?) -> Void) {
    remotelyLinkedAccounts(mode, completion: completion)
  }
  
  /**
   Unlinkes remote authentications for the provided `mode`.
   
   - parameter mode: Mode identifier for which to remove the authentication.
   - parameter remoteURL: `ProviderAuth.actionURL`, required to remove remote authentications.
   - parameter completion: Block executed when unlinking has finished. Boolean parameter indicates if any authentications have been removed.
  */
  @objc public func unlinkAccount(_ mode: String, remoteURL: URL, completion: @escaping (Bool) -> Void) {
    
    // Also unlink remote
    TKServer.get(remoteURL, paras: nil) { _, _, response, _, error in
      if let response = response as? [NSObject: AnyObject],
         response.isEmpty && error == nil {
        completion(true)
      } else {
        completion(false)
      }
    }
    
  }

  func remotelyLinkedAccounts(_ mode: String?, completion: @escaping ([ProviderAuth]?) -> Void) {
    
    var paras = [String: Any]()
    if let mode = mode {
      paras["mode"] = mode
    }
    if UserDefaults.shared.bool(forKey: TKDefaultsKeyProfileBookingsUseSandbox) {
      paras["bsb"] = true
    }
    
    TKServer.shared.hitSkedGo(
      withMethod: "GET",
      path: "auth/\(name)",
      parameters: paras,
      region: self,
      success: { _, _, data in
        if let data = data, let auths = try? JSONDecoder().decode([ProviderAuth].self, from: data) {
          completion(auths)
        } else {
          completion([])
        }
      }, failure: { error in
        completion(nil)
      }
    )
  }
}

extension Reactive where Base: TKRegion {
  
  public func linkedAccounts(mode: String? = nil) -> Observable<[ProviderAuth]?> {
    
    return Observable.create { subscriber in
      
      self.base.linkedAccounts(mode) {
        subscriber.onNext($0)
        subscriber.onCompleted()
      }
      
      return Disposables.create()
      
    }
    
  }
  
}
