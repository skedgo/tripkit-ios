//
//  TKLinkedAccountHelper.swift
//  TripGo
//
//  Created by Adrian Schoenig on 8/04/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import Marshal

import SGBookingKit

public struct ProviderAuth {

  fileprivate struct RemoteAction {
    fileprivate let title: String
    fileprivate let url: URL
  }

  fileprivate enum Status {
    case connected(RemoteAction?)
    case notConnected(RemoteAction)
    
    fileprivate var remoteURL: URL? {
      switch self {
      case .connected(let action):    return action?.url
      case .notConnected(let action): return action.url
      }
    }

    fileprivate var remoteAction: String? {
      switch self {
      case .connected(let action):    return action?.title
      case .notConnected(let action): return action.title
      }
    }
  }

  fileprivate let status: Status
  
  fileprivate let companyInfo: TKCompanyInfo?
  
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

}

extension ProviderAuth.Status {
  fileprivate init?(withDictionary dictionary: [String: AnyObject]) {
    guard let action: String = try? dictionary.value(for: "action"),
          let actionTitle: String = try? dictionary.value(for: "actionTitle"),
          let URLString: String = try? dictionary.value(for: "url"),
          let actionURL = URL(string: URLString)
      else {
      return nil
    }
    
    let remoteAction = ProviderAuth.RemoteAction(title: actionTitle, url: actionURL)
    
    switch action {
    case "signin":
      self = .notConnected(remoteAction)
    case "logout":
      self = .connected(remoteAction)
    default:
      return nil
    }
  }
}

extension ProviderAuth {
  fileprivate init?(withDictionary dictionary: [String: AnyObject]) {
    guard let mode: String = try? dictionary.value(for: "modeIdentifier"),
          let status = Status.init(withDictionary: dictionary)
      else {
        return nil
    }
    
    self.modeIdentifier = mode
    self.status = status
    self.companyInfo = try? dictionary.value(for: "companyInfo")
  }
}

extension SVKRegion {
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
  public func unlinkAccount(_ mode: String, remoteURL: URL, completion: @escaping (Bool) -> Void) {
    
    // Also unlink remote
    SVKServer.get(remoteURL, paras: nil) { _, response, error in
      if let response = response as? [NSObject: AnyObject],
         response.isEmpty && error == nil {
        completion(true)
      } else {
        completion(false)
      }
    }
    
  }

  fileprivate func remotelyLinkedAccounts(_ mode: String?, completion: @escaping ([ProviderAuth]?) -> Void) {
    
    var paras = [String: Any]()
    if let mode = mode {
      paras["mode"] = mode
    }
    if UserDefaults.shared().bool(forKey: TKDefaultsKeyProfileBookingsUseSandbox) {
      paras["bsb"] = true
    }
    
    SVKServer.sharedInstance().hitSkedGo(
      withMethod: "GET",
      path: "auth/\(name)",
      parameters: paras,
      region: self,
      success: { _, response in
        guard let array = response as? [[String: AnyObject]], !array.isEmpty else {
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

extension Reactive where Base: SVKRegion {
  
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
