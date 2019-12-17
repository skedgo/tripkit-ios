//
//  OAuthClient.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 21/03/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import KeychainAccess
import OAuthSwift
import RxSwift

public enum OAuthResult {
  
  case waiting
  case success(next: URL, data: [AnyHashable: Any])
  case error(Error)

  fileprivate static func with(form: BPKForm, oauth: OAuthData) -> OAuthResult {
    guard
      let postURL = form.oauthParameters?.postURL,
      let accessToken = oauth.accessToken,
      let expiration = oauth.expiration,
      let postForm = form.buildOAuthForm(accessToken, refreshToken: oauth.refreshToken, expiration: expiration)
      else {
        return .error(OAuthError.unableToBuildPostForm)
    }
    
    return .success(next: postURL, data: postForm.rawForm)
  }

}

public class OAuthClient {
  
  
  public static let shared = OAuthClient()
  
  private static let keychain = Keychain(service: "com.skedgo.tripkit.oauth")
  
  private init() {
  }
  
  private var client: OAuth2Swift?
  
  public var authenticator: SSOAuthenticator? = nil
  
  
  private static func canHandle(_ url: URL) -> Bool {
    
    if let callback = SGKConfig.shared.oauthCallbackURL(), url.absoluteString.hasPrefix(callback.absoluteString) {
      return true
      
    }
    
    // Check the authenticator, which might throw if it's
    // handling the URL but there's an error encoded in it.
    do {
      let result = try shared.authenticator?.handle(url)
      return result != nil
    } catch {
      // Yes, we can handle it, but there will be an error
      return true
    }
    
  }
  
  /// Initiates a new OAuth flow
  public func rx_initiate(forMode mode: String, form: BPKForm) -> Observable<OAuthResult> {
    
    guard form.isClientSideOAuth else {
      preconditionFailure("Don't call this method if the form is not an OAuth form")
    }
    
    // This is getting the authentication data in the first place, either using SSO or regular OAuth
    guard let callbackURL = SGKConfig.shared.oauthCallbackURL() else {
      preconditionFailure("OAuth callback URL missing in Config.plist")
    }
    guard let oauthParas = form.oauthParameters else {
      return Observable.error(OAuthError.unableToBuildParameters)
    }
    
    let parameters = AuthorizeParameters(mode: mode, form: form, callbackURL: callbackURL, scope: oauthParas.scope, state: String.randomString(length: 128))
    
    if let fromSSO = authenticator?.authenticate(mode) {
      OAuthClient.save(parameters: parameters)
      return fromSSO
        .map { OAuthResult.with(form: form, oauth: $0) }
        .startWith(.waiting)
      
    } else {
      let client = OAuth2Swift(
        consumerKey: oauthParas.clientID,
        consumerSecret: oauthParas.clientSecret,
        authorizeUrl: oauthParas.oauthURL,
        accessTokenUrl: oauthParas.tokenURL,
        responseType: "code"
      )
      client.accessTokenBasicAuthentification = oauthParas.accessTokenBasicAuth
      self.client = client
      
      OAuthClient.save(parameters: parameters, client: client)
      
      return client.rx.authorize(input: parameters)
    }

  }
  
  /// Call to handle URL's that the app gets opened with
  public func rx_handle(_ url: URL) -> Observable<OAuthResult> {
    
    do {
      // Important to NOT enter waiting state here as you could
      // otherwise get infinite loops.
      let observable = try handle(url)
      return observable ?? Observable.empty()

    } catch {
      return Observable.just(.error(error))
    }
    
  }
  
  private func handle(_ url: URL) throws -> Observable<OAuthResult>? {
    if !OAuthClient.canHandle(url) {
      return nil
    }
    
    if let callbackURL = SGKConfig.shared.oauthCallbackURL(), url.absoluteString.hasPrefix(callbackURL.absoluteString) {
      return try handleUsingOAuth(url)
    
    } else {
      return try handleUsingAuthenticator(url)
    }
  }
  
  
  private func handleUsingAuthenticator(_ url: URL) throws -> Observable<OAuthResult>? {
    do {
      guard let result = try authenticator?.handle(url) else { return nil }
      guard let (parameters, _) = OAuthClient.restore() else {
        throw OAuthError.unexpectedCallback
      }
      
      return Observable.just( OAuthResult.with(form: parameters.form, oauth: result.data) )

    } catch {
      return Observable.just( .error(error) )
    }
  }
  
  
  private func handleUsingOAuth(_ url: URL) throws -> Observable<OAuthResult>? {
    // A: Using OAuth, did we get killed an need to restore the client?
    if self.client == nil {
      guard let (parameters, client) = OAuthClient.restore(), let restored = client else {
        throw OAuthError.unexpectedCallback
      }
      
      // 1. Restore client
      class DoNothingURLHandler : NSObject, OAuthSwiftURLHandlerType {
        func handle(_ url: URL) {
          // Not doing anything (as this is just for restoring where we already called a URL)
        }
      }
      self.client = restored
      
      // 2. Don't do anything when we start authorising again as we already have
      //    the handle URL.
      restored.authorizeURLHandler = DoNothingURLHandler()
      
      // 3. Create a callback and handle the URL
      return restored.rx.authorize(input: parameters, handling: url)
      
      // B: Using OAuth, we still have the client
    } else {
      // We already have a client, just handle the URL and don't
      // return anything as we assume that the caller is already
      // registered to `self.client`'s observable when calling
      // `rx_initiate`.
      OAuthSwift.handle(url: url)
      return nil
    }
  }
  
  
  private static func save(parameters: AuthorizeParameters, client: OAuth2Swift? = nil) {
    var toStore = [
      "authorize": parameters
    ] as [String : Any]
    
    toStore["client"] = client?.parameters
    
    let data = NSKeyedArchiver.archivedData(withRootObject: toStore)
    
    // INFO: This is here for updating the testing data.
    // Uncomment, run tests, get the file, and update OAuthClientTest.
//    let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//    let pathURL = path.appendingPathComponent("oauthclient.data")
//    try! data.write(to: pathURL)
//    print(pathURL)
    
    keychain[data: "OAuthClientState"] = data
  }
  
  
  /// Saves the state of a client and its authorisation parameters from the
  /// file at the provided URL to the keychain.
  ///
  /// - warning: Not meant to be called directly, except for testing purposes.
  ///
  /// - parameter url: URL To file from which to restore state.
  /// - returns: If credentials could be read from the provided URL.
  @discardableResult
  public static func saveState(fromFile url: URL) -> Bool {
    
    // Unwrap and package up, to make sure that the contents of the file
    // are what we expect. If we just saved it to the keychain, we could
    // end up with garbage.
    guard
      let data = try? Data(contentsOf: url),
      let state = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: Any],
      let clientParas = state["client"] as? OAuth2Swift.ConfigParameters,
      let authorizeParas = state["authorize"] as? AuthorizeParameters,
      let client = OAuth2Swift(parameters: clientParas)
      else { return false }
    
    save(parameters: authorizeParas, client: client)
    return true
  }
  
  
  /// Restores a client and the parameters sent to its `authorize` method.
  ///
  /// - warning: Not meant to be called directly, except for testing purposes.
  public static func restore() -> (AuthorizeParameters, OAuth2Swift?)? {
    guard
      let data = keychain[data: "OAuthClientState"],
      let state = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: Any],
      let authorizeParas = state["authorize"] as? AuthorizeParameters
      else { return nil }

    let clientParas = state["client"] as? OAuth2Swift.ConfigParameters
    let client = clientParas != nil ? OAuth2Swift(parameters: clientParas!) : nil
    
    return (authorizeParas, client)
  }

  
  /// Clears in-memory caches.
  ///
  /// - warning: Not meant to be called directly, except for testing purposes to simulate that the app got killed.
  public static func clearMemoryCaches() {
    shared.client = nil
  }

  
  /// Clears persistent caches.
  ///
  /// - warning: Not meant to be called directly, except for testing purposes and troubleshooting.
  public static func clearFileCaches() {
    do {
      try keychain.removeAll()
    } catch {
      SGKLog.error("OAuthClient", text: "Error clearing file caches: \(error)")
    }
  }
  
}


extension String {
  
  // Thanks: http://stackoverflow.com/questions/26845307/generate-random-alphanumeric-string-in-swift  
  fileprivate static func randomString(length: Int) -> String {
    
    let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let allowedCharsCount = UInt32(allowedChars.count)
    var randomString = ""
    
    for _ in (0..<length) {
      let randomNum = Int(arc4random_uniform(allowedCharsCount))
      let newCharacter = allowedChars[allowedChars.index(allowedChars.startIndex, offsetBy: randomNum)]
      randomString += String(newCharacter)
    }
    
    return randomString
  }
}


public class AuthorizeParameters : NSObject, NSCoding {
  let mode: String
  let form: BPKForm
  let callbackURL: URL
  let scope: String
  let state: String
  
  fileprivate init(mode: String, form: BPKForm, callbackURL: URL, scope: String, state: String) {
    self.mode = mode
    self.form = form
    self.callbackURL = callbackURL
    self.scope = scope
    self.state = state
    
    super.init()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    guard
      let mode = aDecoder.decodeObject(forKey: "mode") as? String,
      let rawForm = aDecoder.decodeObject(forKey: "rawForm") as? [AnyHashable: Any],
      let callbackURLString = aDecoder.decodeObject(forKey: "callbackURL") as? String,
      let callbackURL = URL(string: callbackURLString),
      let scope = aDecoder.decodeObject(forKey: "scope") as? String,
      let state = aDecoder.decodeObject(forKey: "state") as? String
      else { return nil }

    self.mode = mode
    self.form = BPKForm(json: rawForm)
    self.callbackURL = callbackURL
    self.scope = scope
    self.state = state
  }
  
  public func encode(with aCoder: NSCoder) {
    aCoder.encode(mode, forKey: "mode")
    aCoder.encode(form.rawForm, forKey: "rawForm")
    aCoder.encode(callbackURL.absoluteString, forKey: "callbackURL")
    aCoder.encode(scope, forKey: "scope")
    aCoder.encode(state, forKey: "state")
  }
}


extension Reactive where Base : OAuth2Swift {
  
  fileprivate func authorize(input: AuthorizeParameters, handling: URL? = nil) -> Observable<OAuthResult> {
    
    return Observable.create { observer in
      
      self.base.authorize(
        withCallbackURL: input.callbackURL,
        scope: input.scope,
        state: input.state) { result in
          switch result {
            case .success(let success):
              let data = RawOAuthData(success.parameters)
              observer.onNext( OAuthResult.with(form: input.form, oauth: data) )
              observer.onCompleted()
            case .failure(let error):
              observer.onNext( .error(error) )
              observer.onCompleted()
          }
      }
      
      if let url = handling {
        OAuthSwift.handle(url: url)
        
      } else {
        // After the call to OAuthSwift on purpose
        // to make sure that everything is set up
        observer.onNext(.waiting)
      }
      
      return Disposables.create()
    
    }.share(replay: 1, scope: .forever) // Multiple observers should not trigger multiple `authorize` calls!
    
  }
  
  
}
