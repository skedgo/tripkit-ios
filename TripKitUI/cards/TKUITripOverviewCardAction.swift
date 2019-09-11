//
//  TKUITripOverviewCardAction.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 04.09.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import TripKit

/// An action that can be added to a `TKUITripOverviewCard`. Set an array of
/// these on `TKUITripOverviewCard.tripActionsFactory` and/or
///  on `TKUITripOverviewCard.segmentActionsFactory`.
///
/// See `TKUIStartTripAction` as an example.
public protocol TKUITripOverviewCardAction {
  /// Title (and accessory label) of the button
  var title: String { get }
  
  /// Icon to display as the action. Should be a template image.
  var icon: UIImage { get }
  
  var style: TKUICardActionStyle { get }
  
  /// Handler executed when user taps on the button, providing the
  /// corresponding card and trip. Should return whether the button should
  /// be refreshed as its title or icon changed as a result (e.g., for
  /// toggle actions such as adding or removing a reminder or favourite).
  ///
  /// Parameters are the card, the trip, and the sender
  var handler: (TKUITripOverviewCard, UIView) -> Bool { get }
}

public extension TKUITripOverviewCardAction {
  var style: TKUICardActionStyle { .normal }
}

public struct TKUIStartTripAction: TKUITripOverviewCardAction {
  public init() {}
  
  public let title: String = Loc.ActionGo
  public let icon: UIImage = .iconArrowUp
  public let style: TKUICardActionStyle = .bold
  
  public var handler: (TKUITripOverviewCard, UIView) -> Bool {
    return { card, _ in
      guard
        let mapManager = card.mapManager as? TKUITripMapManager,
        let controller = card.controller
        else { assertionFailure(); return false }
      
      let modeByMode = TKUITripModeByModeCard(mapManager: mapManager)
      modeByMode.modeByModeDelegate = card
      controller.push(modeByMode)
      return false
    }
  }
}
