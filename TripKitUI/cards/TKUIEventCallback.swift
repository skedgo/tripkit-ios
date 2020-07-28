//
//  TKUIEventCallback.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 27.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController

/// This struct provides a single `handler` which is called when certain user events fire from the user
/// interacting with the TripKitUI SDK.
///
/// Typical uses are to track how users interact with the SDK, provide context in error reports, or prompt
/// the user for ratings when certain screens or cards are displayed frequently.
///
/// To inject your own custom actions into the SDK and track those don't use this, but rather use the different
/// `Configuration` options on the different cards, such as `TKUITripOverviewCard.Configuration`.
public struct TKUIEventCallback {
  
  /// Enumeration of possible events that fire when a user interacts with the different components of the TripKitUI SDK.
  ///
  /// Passed to `TKUIEventCallback.handler`
  public enum Event {
    /// Fires whenever a card appears, including when going back to a previous card or when the card re-appears after presenting some other screen on top.
    case cardAppeared(TGCard)
    
    /// Fires when a particular screen appears, often presented modally from a card
    case screenAppeared(name: String, controller: UIViewController)
    
    /// Fires whenever the details of a trip are viewed
    case tripSelected(Trip)
  }
  
  private init() {}
  
  
  /// Set this global handler to be notified of any events that the user undertakes.
  public static var handler: (Event) -> Void = { _ in }
  
}
