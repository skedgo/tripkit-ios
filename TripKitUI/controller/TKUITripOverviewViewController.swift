//
//  TKUITripOverviewViewController.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 29.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController

import TripKit

public protocol TKUITripOverviewViewControllerDelegate: TGCardViewControllerDelegate {
  func tripOverview(_ controller: TKUITripOverviewViewController, selected trip: Trip)
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
    super.init(nibName: "TGCardViewController", bundle: TGCardViewController.bundle)
    
    let tripCard = TKUITripOverviewCard(trip: trip)
    tripCard.style = TKUICustomization.shared.cardStyle
    tripCard.selectedAlternativeTripCallback = { [weak self] trip in
      guard let self = self, let delegate = self.delegate as? TKUITripOverviewViewControllerDelegate else { return true }
      delegate.tripOverview(self, selected: trip)
      return false
    }
    rootCard = tripCard
  }
  
  required public init(coder aDecoder: NSCoder) {
    fatalError("Use the `init(trip:)` method instead.")
  }
  
}
