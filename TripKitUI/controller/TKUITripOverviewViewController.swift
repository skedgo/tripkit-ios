//
//  TKUITripOverviewViewController.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 29.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController

public protocol TKUITripOverviewViewControllerDelegate: TGCardViewControllerDelegate {
}

/// The `TKUITripOverviewViewController` class provides a user interface for viewing a individual trip.
///
/// Customisation points:
/// - `TKUICustomization` for the visual style of the cards
/// - `TKUITripOverviewCard.config` for the trip details
/// - `TKUITripModeByModeCard.config` for the step-by-step details of a trip
public class TKUITripOverviewViewController: TGCardViewController {
  
  /// Configure for showing a previously calculated trip
  ///
  /// - Parameter destination: The trip object, e.g., previously calculated via `TKRouter`
  public init(trip: Trip) {
    super.init(nibName: "TGCardViewController", bundle: Bundle(for: TGCardViewController.self))
    
    let tripCard = TKUITripOverviewCard(trip: trip)
    tripCard.style = TKUICustomization.shared.cardStyle
    rootCard = tripCard
  }
  
  required public init(coder aDecoder: NSCoder) {
    fatalError("Use the `init(trip:)` method instead.")
  }
  
}
