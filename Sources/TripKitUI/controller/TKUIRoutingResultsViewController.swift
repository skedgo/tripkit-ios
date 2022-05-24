//
//  TKUIRoutingResultsViewController.swift
//  TripKitUI
//
//  Created by Adrian Schoenig on 17.10.17.
//

import UIKit
import MapKit

import TGCardViewController

import TripKit

@available(*, unavailable, renamed: "TKUIRoutingResultsViewController")
public typealias TKUIRoutesViewController = TKUIRoutingResultsViewController

@available(*, unavailable, renamed: "TKUIRoutingResultsViewControllerDelegate")
public typealias TKUIRoutesViewControllerDelegate = TKUIRoutingResultsViewControllerDelegate


public protocol TKUIRoutingResultsViewControllerDelegate: TGCardViewControllerDelegate {
  
}

/// The `TKUIRoutingResultsViewController` class provides a user interface for viewing
/// routing options.
///
/// Upon selection of a route by the user, the details of the trip will be
/// displayed.
///
/// Customisation points:
/// - ``TKUICustomization`` for the visual style of the cards
/// - `TKUIRoutingResultsCard.config` for the comparison of routing options
/// - `TKUITripOverviewCard.config` for the trip details
/// - `TKUITripModeByModeCard.config` for the step-by-step details of a trip
public class TKUIRoutingResultsViewController: TGCardViewController {
  
  /// Configure for showing the routes from the user's current location
  /// to the provided location leaving now.
  ///
  /// - Parameter destination: Destination of the trip
  public init(destination: MKAnnotation) {
    super.init(nibName: "TGCardViewController", bundle: TGCardViewController.bundle)

    let resultsCard = TKUIRoutingResultsCard(destination: destination)
    resultsCard.style = TKUICustomization.shared.cardStyle
    rootCard = resultsCard
  }

  /// Configure for showing the routes for the provided trip request
  ///
  /// Use this when you want to customise the departure location to something
  /// other than the user's current location, or when you want to set the
  /// departure or arrival time.
  ///
  /// - Parameter request: The trip request object, which should be instatiated
  ///     using `TripRequest.insert(from:to:for:timeType:info:)`
  public init(request: TripRequest) {
    super.init(nibName: "TGCardViewController", bundle: TGCardViewController.bundle)

    let resultsCard = TKUIRoutingResultsCard(request: request)
    resultsCard.style = TKUICustomization.shared.cardStyle
    rootCard = resultsCard
  }
  
  required public init(coder aDecoder: NSCoder) {
    fatalError("Use the `init(destination:)` or `init(request:) methods instead.")
  }
  
}
