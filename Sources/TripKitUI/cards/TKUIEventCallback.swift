//
//  TKUIEventCallback.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 27.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

import TGCardViewController
import RxSwift

import TripKit


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
    
    /// Fires whenever the details of a trip are viewed.
    ///
    /// You can use the `DisposeBag` to trigger an action that should be cancelled if the trip
    /// is no longer selected.
    case tripSelected(Trip, controller: TGCardViewController, DisposeBag)

    /// Fires whenever the routing results were requested and finished loading
    case routesLoaded(TripRequest, controller: TGCardViewController)
    
    /// Fires when a timetable is viewed
    case timetableSelected(TKTimetable, controller: TGCardViewController)
  }
  
  private init() {}
  
  
  /// Set this global handler to be notified of any events that the user undertakes.
  public static var handler: @MainActor (Event) -> Void = { _ in }
  
}
