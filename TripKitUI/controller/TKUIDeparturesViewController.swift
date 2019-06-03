//
//  TKUIDeparturesViewController.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 24.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TGCardViewController

public protocol TKUIDeparturesViewControllerDelegate: TGCardViewControllerDelegate {
  
}

/// The `TKUIDeparturesViewController` class provides a user interface for
/// viewing the departures from a public transport stop or for viewing the
/// public transport connections between two public transport stops.
///
/// Upon selection of a departure by the user, the details of the service
/// will be displayed.
///
/// Customisation points:
/// - `TKUICustomization` for the visual style of the cards
/// - `TKUIDeparturesCard.config` for the list of departures
public class TKUIDeparturesViewController: TGCardViewController {
  
  /// Configure for showing the departures from a public transport stop.
  ///
  /// Make sure that the stop provides the correct region and stop code, or
  /// otherwise you'll get a blank view. Best to use stop annotations provided
  /// from TripKit, e.g., from `TKSkedGoGeocoder`.
  ///
  /// - Parameter stop: The stop for which to show departures, includes
  ///     departures from any child stops (e.g., platforms)
  public init(stop: TKUIStopAnnotation) {
    super.init(nibName: "TGCardViewController", bundle: Bundle(for: TGCardViewController.self))
    
    let departuresCard = TKUIDeparturesCard(stops: [stop])
    departuresCard.style = TKUICustomization.shared.cardStyle
    rootCard = departuresCard
  }
  
  /// Configure for showing the connections between two public transport stops.
  ///
  /// - Parameters:
  ///   - dlsTable: The object describing what pair of stops for which you
  ///       want connections
  ///   - startDate: Optional date of first connection, defaults to current time
  public init(dlsTable: TKDLSTable, startDate: Date = Date()) {
    super.init(nibName: "TGCardViewController", bundle: Bundle(for: TGCardViewController.self))
    
    let departuresCard = TKUIDeparturesCard(dlsTable: dlsTable, startDate: startDate)
    departuresCard.style = TKUICustomization.shared.cardStyle
    rootCard = departuresCard
    
  }
  
  required public init(coder aDecoder: NSCoder) {
    fatalError("Use the `init(stops:)` or `init(dlsTable:startDate:) methods instead.")
  }
  
}
