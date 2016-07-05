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

import SGBookingKit

public struct ProviderAuth {

  private struct RemoteAction {
    private let title: String
    private let URL: NSURL
  }

  private enum Status {
    case Connected(RemoteAction?)
    case NotConnected(RemoteAction)
    
    private var remoteURL: NSURL? {
      switch self {
      case .Connected(let action): return action?.URL
      case .NotConnected(let action): return action.URL
      }
    }

    private var remoteAction: String? {
      switch self {
      case .Connected(let action): return action?.title
      case .NotConnected(let action): return action.title
      }
    }
  }

  private let status: Status
  
  /// Mode identifier that this authentication is for
  public let modeIdentifier: String
  
  /// Current authentication status
  public var isConnected: Bool {
    switch status {
    case .Connected: return true
    case .NotConnected: return false
    }
  }

  /// Title  for button to change authentication status
  public var action: String {
    if let remoteAction = status.remoteAction {
      return remoteAction
    }
    
    switch status {
    case .Connected: return "Disconnect"
    case .NotConnected: return "Setup"
    }
  }
  
  /// Optional URL to either link or unlink the account. 
  /// Only available if user has an account.
  public var actionURL: NSURL? {
    return status.remoteURL
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
  }
}

extension SVKRegion {
  /**
   Fetches authentications for the provided `mode`.
   
   Authentications can be locally stored (requiring no logins) or associated with the user's account and stored server-side. This method first tries locally and then falls back to remotely.
   
   - parameter mode: Mode identifier for which to fetch accounts. If `nil`, accounts for all modes will be fetched.
   - parameter completion: Block executed on completion with list of accounts that can be linked.
  */
  public func linkedAccounts(mode: String? = nil, completion: [ProviderAuth]? -> Void) {
    if let mode = mode, account = locallyLinkedAccount(mode) {
      completion([account])
    } else {
      remotelyLinkedAccounts(mode, completion: completion)
    }
  }
  
  /**
   Initiates linking of a user's account for the provided `mode`.
   
   Fetches the required information from the server to initiate the OAuth process and then starts the OAuth process itself, which usually leads to the user being redirected to a webpage.
   
   - warning: Make sure you have configured the OAuthCallback in your Config.plist and that you're handling this when the app gets opened again.
   
   - parameter mode: Mode identifier for which to link the user's account.
   - parameter remoteURL: URL for linking from `ProviderAuth.actionURL`.
   - returns: Observable indicating success.
  */
  public func rx_linkAccount(mode: String, remoteURL: NSURL, presenter: UIViewController) -> Observable<Bool> {
    return OAuthClient.requiresOAuth(remoteURL)
      .flatMap { form, isOAuth -> Observable<Bool> in
        if isOAuth {
          return OAuthClient.performOAuth(mode, form: form)
            .map { form in form == nil } // No further input required
        } else {
          var manager: MiniBookingManager! = MiniBookingManager(withForm: form)
          manager.present(fromViewController: presenter)
          return Observable.create { subscriber in
            manager.asObservable().subscribe(subscriber)
            return AnonymousDisposable {
              manager = nil
            }
          }
        }
      }
  }
  
  /**
   Unlinkes local and remote authentications for the provided `mode`.
   
   - parameter mode: Mode identifier for which to remove the authentication.
   - parameter remoteURL: `ProviderAuth.actionURL`, required to remove remote authentications.
   - parameter completion: Block executed when unlinking has finished. Boolean parameter indicates if any authentications have been removed.
  */
  public func unlinkAccount(mode: String, remoteURL: NSURL?, completion: Bool -> Void) {
    let localRemoved = OAuthClient.removeCredentials(mode: mode)
    
    guard let URL = remoteURL else {
      completion(localRemoved)
      return
    }
    
    // Also unlink remote
    SVKServer.GET(URL, paras: nil) { response, error in
      if let response = response as? [NSObject: AnyObject]
        where response.isEmpty && error == nil {
        completion(true || localRemoved)
      } else {
        completion(false)
      }
    }
    
  }

  private func locallyLinkedAccount(mode: String) -> ProviderAuth? {
    if let cached = OAuthClient.cachedCredentials(mode: mode) {
      if (cached.isValid || cached.hasRefreshToken) {
        let status = ProviderAuth.Status.Connected(nil)
        return ProviderAuth(status: status, modeIdentifier: mode)
      } else {
        // Remove outdated credentials that we can't renew
        OAuthClient.removeCredentials(mode: mode)
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

/**
 A small class that manages a booking form which is not tied to a trip.
 
 It walks through the booking flow and you can use the `asObservable()` method to be notified once the use has either completed or aborted the booking process. This class handles presenting the booking view controller and dismissing it.
 
 Use it as follows:
 
 1. Initialise it with a form
 2. Call it to present from a view controller
 3. Subscribe to the `asObservable()` as handle its callbacks
 
 - note: This is a one-off object. Only use it to present exactly once. One the observable sequence has ended, this object is useless. 
 */
class MiniBookingManager: NSObject, BPKBookingViewControllerDelegate {
  
  private let form: BPKForm
  private let subject = PublishSubject<Bool>()
  
  private weak var presenter: UIViewController?
  
  init(withForm form: BPKForm) {
    self.form = form
  }
  
  func present(fromViewController presenter: UIViewController) {
    if self.presenter != nil {
      SGKLog.warn("MiniBookingManager", text: "Is already being presented!")
      return
    }
    
    let booker = BPKBookingViewController(form: form)
    booker.delegate = self
    let navigator = UINavigationController(rootViewController: booker)
    navigator.modalPresentationStyle = .FormSheet
    presenter.presentViewController(navigator, animated: true, completion: nil)
    self.presenter = presenter
  }
  
  func asObservable() -> Observable<Bool> {
    return subject.asObservable()
  }
  
  func bookingViewController(controller: BPKBookingViewController, didRequestUpdate url: NSURL, handler: () -> Void) {
    assert(false, "Don't use MiniBM for trips!")
  }
  
  func bookingViewController(controller: BPKBookingViewController, didComplete complete: Bool, withManager manager: BPKManager) {
    self.presenter?.dismissViewControllerAnimated(true, completion: nil)
    self.presenter = nil
    
    subject.onNext(complete)
    subject.onCompleted()
  }
  
  func bookingViewControllerDidCancelBooking(controller: BPKBookingViewController) {
    self.presenter?.dismissViewControllerAnimated(true, completion: nil)
    self.presenter = nil
    
    subject.onNext(false)
    subject.onCompleted()
  }
}
