//
//  TKUITripOverviewCardAction.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 04.09.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

import TGCardViewController

extension TKUITripOverviewCard {
  
  /// Creates a trip action with a "Go" title and arrow icon to indicate starting a trip
  ///
  /// - Parameter actionHandler: Optional handler, passed to `TKUITripModeByModeCard.tripStartedHandler`.
  /// - Returns: A new trip action to be used on a `TKUITripOverviewCard`
  public static func buildStartTripAction(startingOn: TKSegment? = nil, 
                                          label: String? = nil,
                                          mode: TKUISegmentMode = .getReady, 
                                          actionHandler: TKUITripModeByModeCard.TripStartedActionHandler? = nil) -> TKUITripOverviewCard.TripAction {
    return TKUICardAction(
      title: label ?? Loc.ActionGo,
      icon: .iconArrowUp
    ) { _, card, trip, _ in
      guard let controller = card.controller else { assertionFailure(); return false }
      
      var modeByModeCard: TKUITripModeByModeCard!
      if let startingOn = startingOn {
        modeByModeCard = try? TKUITripModeByModeCard(startingOn: startingOn, mode: mode, mapManager: card.mapManager as? TKUITripMapManager)
      }
      
      if let mapManager = card.mapManager as? TKUITripMapManager {
        modeByModeCard = modeByModeCard ?? TKUITripModeByModeCard(mapManager: mapManager)
      } else {
        modeByModeCard = modeByModeCard ?? TKUITripModeByModeCard(trip: trip)
      }
      modeByModeCard.tripStartedHandler = actionHandler
      modeByModeCard.modeByModeDelegate = card as? TKUITripOverviewCard
      
      controller.push(modeByModeCard)
      
      return false
    }
  }
  
}

