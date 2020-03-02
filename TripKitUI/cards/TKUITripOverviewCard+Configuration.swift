//
//  TKUITripOverviewCardConfiguration.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//


public extension TKUITripOverviewCard {
  
  /// Configurtion of any `TKUITripOverviewCard`. Use this to add custom
  /// actions.
  ///
  /// This isn't created directly, but rather you modify the static instance
  /// accessible from `TKUITripOverviewCard.config`.
  struct Configuration {
    private init() {}
    
    static let empty = Configuration()
    
    /// Called when the user taps on an item in the attribution view, and
    /// requests displaying that URL. You should then either present it in an
    /// in-app web view, or call `UIApplication.shared.open()`.
    ///
    /// - warning: Make sure you provide this.
    public var presentAttributionHandler: ((TKUITripOverviewCard, TKUIAttributionTableViewController, URL) -> Void)?
    
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
    
    /// Set this to add a list of action buttons to a trip overview card.
    ///
    /// - warning: Only a maximum of three actions can be accomodated. Any
    ///     more than that will be ignored.
    ///
    /// Called when a trip overview card gets presented.
    public var tripActionsFactory: ((Trip) -> [TKUITripOverviewCardAction])?
    
    /// Set this to add a list of action buttons to a segment on the trip overview card.
    ///
    /// - warning: Only a maximum of three actions can be accomodated. Any
    ///     more than that will be ignored.
    ///
    /// Called when a trip overview card gets presented.
    public var segmentActionsfactory: ((TKSegment) -> [TKUITripOverviewCardAction])?
    
    /// Set this to limit how many alerts are shown for a segment
    public var maximumAlertsPerSegment: Int = 3
  }
}

extension TKUITripOverviewCard: TKUITripModeByModeCardDelegate {
  public func modeByModeRequestsRebuildForNewSegments(_ card: TKUITripModeByModeCard, trip: Trip, currentSegment: TKSegment) {
    TKLog.debug("TKUITripOverviewCard") { "Swapping page card as segments changed." }
    
    guard let mapManager = card.mapManager as? TKUITripMapManager else {
      return assertionFailure()
    }
    let newPager = try! TKUITripModeByModeCard(startingOn: currentSegment, mapManager: mapManager)
    controller?.swap(for: newPager, animated: true)
  }
}
