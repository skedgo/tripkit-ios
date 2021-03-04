//
//  TKUITripOverviewCardConfiguration.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import TGCardViewController

public extension TKUITripOverviewCard {
  
  typealias TripAction = TKUICardAction<TGCard, Trip>
  typealias SegmentAction = TKUICardAction<TKUITripOverviewCard, TKSegment>
  
  /// Configurtion of any `TKUITripOverviewCard`. Use this to add custom
  /// actions.
  ///
  /// This isn't created directly, but rather you modify the static instance
  /// accessible from `TKUITripOverviewCard.config`.
  struct Configuration {
    private init() {}
    
    static let empty = Configuration()

    /// Set this to add a tap-action to every segment in the trip overview
    /// card.
    ///
    /// Handler will be called when the user taps the segment. You can, for
    /// example, use this to present a detailed view of the segment.
    ///
    /// By default pushes a `TKUITripModeByModeCard` starting on this segment
    public var presentSegmentHandler: ((TKUITripOverviewCard, TKSegment) -> Void)? = { card, segment in
      guard let mapManager = card.mapManager as? TKUITripMapManager else {
        assertionFailure(); return
      }
      let pageCard = try! TKUITripModeByModeCard(startingOn: segment, mapManager: mapManager)
      pageCard.modeByModeDelegate = card
      card.controller?.push(pageCard)
    }
    
    /// Set this to use your own map manager. You can use this in combination
    /// with `TGCardViewController.builder` to use a map other than Apple's
    /// MapKit.
    ///
    /// Defaults to using `TKUITripMapManager`.
    public var mapManagerFactory: ((Trip) -> TKUITripMapManagerType) = TKUITripMapManager.init
    
    
    // MARK: - Customising trip actions
    
    /// Set this to add a list of action buttons to a trip overview card.
    ///
    /// These will also be exposed as context actions on the `TKUIRoutingResultsCard`.
    ///
    /// - warning: Only a maximum of three actions can be accomodated. Any
    ///     more than that will be ignored.
    ///
    /// Called when a trip overview card gets presented.
    public var tripActionsFactory: ((Trip) -> [TripAction])?
    
    /// This controls whether the title is visible underneath an action icon.
    ///
    /// The default is `false`, which means actions are displayed as icons
    /// only. We recommend that choosing an action icon that is immediately
    /// obvious what it does and avoids having to set this to `true`. If this
    /// must be set to `true`, we recommend that the titles for your actions
    /// are short, otherwise, some of the titles may be truncated.
    ///
    /// - note: This only applies to actions that are arranged in a compact
    ///     layout
    public var showTripActionTitle: Bool = false
    
    // MARK: - Customising segment actions
    
    /// Set this to add a list of action buttons to a segment on the trip overview card.
    ///
    /// - warning: Only a maximum of three actions can be accomodated. Any
    ///     more than that will be ignored.
    ///
    /// Called when a trip overview card gets presented.
    public var segmentActionsfactory: ((TKSegment) -> [SegmentAction])?
    
    /// Set this to limit how many alerts are shown for a segment
    public var maximumAlertsPerSegment: Int = 3
  }
}
