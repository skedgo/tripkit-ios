//
//  TKUIEventCallback.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 27.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController

public struct TKUIEventCallback {
  
  public enum Event {
    /// Fires whenever a card appears, including when going back to a previous card or when the card re-appears after presenting some other screen on top.
    case cardAppeared(TGCard)
    
    /// Fires whenever the details of a trip are viewed
    case tripSelected(Trip)
  }
  
  private init() {}
  
  
  /// Set this global handler to be notified of any events that the user undertakes
  public static var handler: (Event) -> Void = { _ in }
  
}
