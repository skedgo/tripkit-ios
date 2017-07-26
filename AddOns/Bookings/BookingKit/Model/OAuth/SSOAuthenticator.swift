//
//  SSOAuthenticator.swift
//  TripKit
//
//  Created by Adrian Schoenig on 7/10/16.
//
//

import Foundation

import RxSwift

/// Class-level protocol for Single-Sign-On providers.
/// Used in conjunction with `SSOCAuthenticator`, which is
/// in turn used as an alternative to regular OAuth by
/// `OAuthClient`.
public protocol SSOCompatible {
 
  static var mode: String { get }
  
  /// Check whether this provider can handle authentication
  /// for the provided mode (identifier). Use this both to
  /// check for the mode and for the SSO-partner app being
  /// installed.
  static func canHandle(mode: String) -> Bool
  
  /// Kicks off the SSO authentication, typically by launching
  /// the SSO-partner app.
  static func start()
  
  /// Handling the callback from the SSO-partner app.
  static func handle(_ url: URL) throws -> OAuthData?
  
}


/// Single-Sign-On authentication helper that's used by
/// `OAuthClient`. Best to only have one of these for your
/// application and instatinating it with all possible SSO
/// providers.
public class SSOAuthenticator {
  
  private enum Error: Swift.Error {
    case authenticationFailed
  }
  

  private let providers: [SSOCompatible.Type]
  private var active: (provider: SSOCompatible.Type, subject: PublishSubject<OAuthData>)? = nil

  public init(providers: [SSOCompatible.Type]) {
    self.providers = providers
  }
  
  /// Call this to start authenticating via Single-Sign-on.
  /// If any of the providers supports this mode, then an observable will be
  /// returned or `nil` otherwise.
  func authenticate(_ mode: String) -> Observable<OAuthData>? {
    
    for provider in providers {
      guard provider.canHandle(mode: mode) else {
        continue
      }
      
      let subject = PublishSubject<OAuthData>()
      provider.start()
      active = (provider, subject)
      return subject.asObservable()
    }
    
    return nil
  }
  
  /// Call with URL that has been passed to application delegate when
  /// app is launched from a URL.
  public func handle(_ url: URL) throws -> (mode: String, data: OAuthData)? {
    
    if let active = try handleActive(url) {
      return active
    } else {
      
      for provider in providers {
        if let data = try provider.handle(url) {
          return (provider.mode, data)
        }
      }
      return nil
      
    }
    
  }
  
  private func handleActive(_ url: URL) throws -> (mode: String, data: OAuthData)? {
    guard let active = self.active else { return nil }
    defer { self.active = nil }
    
    if let data = try active.provider.handle(url) {
      active.subject.onNext(data)
      active.subject.onCompleted()
      return (active.provider.mode, data)
    
    } else {
      active.subject.onError(Error.authenticationFailed)
      return nil
    }
    
  }
  
}
