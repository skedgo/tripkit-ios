//
//  TKBookingStateMachine.swift
//  TripGo
//
//  Created by Adrian Schoenig on 31/10/16.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import SGBookingKit

/// A state machine for booking a trip.
///
/// It handles all the different states and transitions that the 
/// booking process can go through.
///
/// Even though there's a large number of states, there's only a small 
/// number of possible transitions for each state. States are modelled
/// as enum values, transitions are modelled as methods.
///
/// The states handle which booking is being viewed or booked, where
/// the app is at with authenticating the user (which can involve
/// switching to other apps and this app getting killed and restored),
/// as well as the different actions that the app needs to take.
///
/// The inputs are of the following kinds:
/// - User interaction
/// - Server callbacks
/// - iOS callbacks
/// - App logic
///
/// - note: The enum itself does *not* do any of the work related to
///     performing transition itself. The `TKBookingTransitioner` takes
///     care of the server and auth transitions.
public enum TKBookingStateMachine {
  
  /// User is viewing quick booking item with
  /// index `selection` in the list of quick
  /// bookings for the segment.
  case viewingQuickBooking(Int?)
  
  /// User has initiated booking, but the
  /// booking coordinator is still working
  /// out the details.
  /// Show a loading indicator.
  case fetchingBookingForm(URL, data: Any?, sender: Any?)

  /// User needs to go through a booking form
  /// before the booking can be completed.
  case presentForm(BPKForm, sender: Any?)

  /// User needs to go through a web form
  /// before the booking can be completed.
  /// Show the URL and monitor for the
  /// user navigating to `disregardOn`.
  ///
  /// The `next` information is then for
  /// deciding the following transition.
  case presentWeb(URL, disregardOn: URL, next: URL, sender: Any?)
  
  /// Booking completed and trip should be
  /// updated with provided URL.
  case completed(URL?)

  /// An error occured during the booking
  /// process. Show error and go back to
  /// `boookingInitiated` state.
  case error(Error)
  
  /// User has initiated booking, authorization
  /// is needed and will be triggered.
  /// Show a loading indicator.
  case authorizing(BPKForm)
  
  ///
  case authWaitingForCallback
  case authCallbackRetrieved(URL)
  case authAppBecameActive
  
  
  // MARK: iOS Callbacks
  
  public mutating func appDidRestore(selection: Int, isWaiting: Bool) {
    
    switch self {
    case .viewingQuickBooking, .authorizing, .error:
      if isWaiting {
        self = .authWaitingForCallback
      } else {
        self = .viewingQuickBooking(selection)
      }
    default: print("Safely ignoring appDidRestore as we're in state \(self)")
    }
    
  }
  
  public mutating func appDidBecomeActive() {
    
    switch self {
    case .authWaitingForCallback:
      self = .authAppBecameActive
    case .error:
      self = .viewingQuickBooking(nil)
    default: print("Safely ignoring appDidBecomeActive as we're in state \(self)")
    }
    
  }

  public mutating func appHandleCallback(_ url: URL) {
    
    switch self {
    case .presentWeb(_, let disregard, let next, _):
      if url.absoluteString.hasPrefix(disregard.absoluteString) {
        self = .fetchingBookingForm(next, data: nil, sender: nil)
      }
      
    case .authWaitingForCallback:
      self = .authCallbackRetrieved(url)
    
    default: print("Safely ignoring appHandleCallback as we're in state \(self)")
    }
    
  }
  
  
  // MARK: Server calls
  
  public mutating func serverDidLoad(form: TKBookingFormType) {
    
    switch self {
    case .fetchingBookingForm(_, _, let sender):
      
      switch form {
      case .auth(let form):           self = .authorizing(form)
      case .form(let form):           self = .presentForm(form, sender: sender)
      case .web(let url, let target, let next):
        self = .presentWeb(url, disregardOn: target, next: next, sender: sender)
      case .trip(let url):            self = .completed(url)
      case .emptyResponse:            self = .completed(nil)
      }
      
    default: print("Uh-oh. Ignoring serverDidLoad as we're in state \(self)")
    }
    
  }

  
  public mutating func formCompletedBooking(url: URL?) {
    
    switch self {
    case .presentForm:
      self = .completed(url)
    default: print("Uh-oh. Ignoring userCompletedBooking as we're in state \(self)")
    }
    
  }
  
  
  // MARK: Auth calls
  
  public mutating func handleOAuth(_ result: OAuthResult) {

    switch result {
    case .waiting:                    self = .authWaitingForCallback
    case .success(let url, let data): self = .fetchingBookingForm(url, data: data, sender: nil)
    case .error(let error):           self =  .error(error)
    }
    
  }
  
  
  // MARK: User interaction
  
  public mutating func userPicked(selection: Int) {
    
    switch self {
    case .viewingQuickBooking(let previous) where previous != selection:
      self = .viewingQuickBooking(selection)
    case .viewingQuickBooking:
    break // selection didn't change
    case .error:
      self = .viewingQuickBooking(selection)
    default: print("Uh-oh. Ignoring userPicked as we're in state \(self)")
    }
    
  }
  
  
  public mutating func userStartedBooking(url: URL, sender: Any?) {
    
    switch self {
    case .viewingQuickBooking, .error:
      self = .fetchingBookingForm(url, data: nil, sender: sender)
    default: print("Uh-oh. Ignoring userStartBooking as we're in state \(self)")
    }
    
  }
  
  
  public mutating func userAccepted(nextURL: URL) {
    
    switch self {
    case .presentForm:
      self = .fetchingBookingForm(nextURL, data: nil, sender: nil)
    default: print("Uh-oh. Ignoring userAccepted as we're in state \(self)")
    }
    
  }

  
  public mutating func userOpenedDisregardURL() {
    
    switch self {
    case .presentWeb(_, _, let next, let sender):
      self = .fetchingBookingForm(next, data: nil, sender: sender)
    default: print("Uh-oh. Ignoring userOpenedDisregardURL as we're in state \(self)")
    }
    
  }
  
  
  public mutating func userDidDismiss() {
    
    switch self {
    case .presentForm, .presentWeb:
      self = .viewingQuickBooking(nil)
    default: print("Uh-oh. Ignoring userDidDismiss as we're in state \(self)")
    }
    
  }
  
}

public func ==(lhs: TKBookingStateMachine, rhs: TKBookingStateMachine) -> Bool {
  switch (lhs, rhs) {
    
  // Simple states
  case (.authorizing, .authorizing),
       (.authWaitingForCallback, .authWaitingForCallback),
       (.authAppBecameActive, .authAppBecameActive),
       (.authCallbackRetrieved, .authCallbackRetrieved):
    return true
    
  case (.viewingQuickBooking(let left), .viewingQuickBooking(let right)):
    return left == right
    
  case (.fetchingBookingForm(let left), .fetchingBookingForm(let right)):
    return left.0 == right.0 // Ignoring data, complicated to equate
    
  case (.presentForm, .presentForm):
    return true // Ignoring type of form
    
  case (.presentWeb(let left), .presentWeb(let right)):
    return left.0 == right.0 && left.1 == right.1 && left.2 == right.2
    
  case (.completed(let left), .completed(let right)):
    return left == right
    
  case (.error, .error):
    return true // Ignoring type of error
    
  default: return false
  }
}

extension TKBookingStateMachine : Equatable {
}
