//
//  TKUITimetableViewController.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 24.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TGCardViewController

import TripKit

@available(*, unavailable, renamed: "TKUITimetableViewController")
public typealias TKUIDeparturesViewController = TKUITimetableViewController

@available(*, unavailable, renamed: "TKUITimetableViewControllerDelegate")
public typealias TKUIDeparturesViewControllerDelegate = TKUITimetableViewControllerDelegate

public protocol TKUITimetableViewControllerDelegate: TGCardViewControllerDelegate {
  
  /// A callback used to notify that the filtering string has changed in the searh bar.
  ///
  /// - Parameters:
  ///   - controller: The timetable view controller within which the filtering takes place
  ///   - filter: The latest filtering string
  func timetableViewController(_ controller: TKUITimetableViewController, updatedFilter filter: String)
  
}

/// The `TKUITimetableViewController` class provides a user interface for
/// viewing the departures from a public transport stop or for viewing the
/// public transport connections between two public transport stops.
///
/// Upon selection of a departure by the user, the details of the service
/// will be displayed.
///
/// Customisation points:
/// - `TKUICustomization` for the visual style of the cards
/// - `TKUITimetableCard.config` for the list of departures
public class TKUITimetableViewController: TGCardViewController {
  
  public var timetableDelegate: TKUITimetableViewControllerDelegate?
  
  /// Configure for showing the departures from a public transport stop.
  ///
  /// Make sure that the stop provides the correct region and stop code, or
  /// otherwise you'll get a blank view. Best to use stop annotations provided
  /// from TripKit, e.g., from `TKTripGoGeocoder`.
  ///
  /// - Parameters:
  ///   - stop: The stop for which to show departures, includes departures
  ///   from any child stops (e.g., platforms)
  ///   - filter: An optional string used to filter the resulting departures
  public init(stop: TKUIStopAnnotation, filter: String? = nil) {
    super.init(nibName: "TGCardViewController", bundle: TGCardViewController.bundle)
    
    let timetableCard = TKUITimetableCard(stops: [stop])
    timetableCard.style = TKUICustomization.shared.cardStyle
    timetableCard.filter = filter
    timetableCard.filterUpdatedHandler = { [weak self] filter in
      guard let self = self else { return }
      self.timetableDelegate?.timetableViewController(self, updatedFilter: filter)
    }
    rootCard = timetableCard
  }
  
  /// Configure for showing the connections between two public transport stops.
  ///
  /// - Parameters:
  ///   - dlsTable: The object describing what pair of stops for which you
  ///       want connections
  ///   - startDate: Optional date of first connection, defaults to current time
  public init(dlsTable: TKDLSTable, startDate: Date = Date()) {
    super.init(nibName: "TGCardViewController", bundle: TGCardViewController.bundle)
    
    let timetableCard = TKUITimetableCard(dlsTable: dlsTable, startDate: startDate)
    timetableCard.style = TKUICustomization.shared.cardStyle
    rootCard = timetableCard
  }
  
  required public init(coder aDecoder: NSCoder) {
    fatalError("Use the `init(stops:)` or `init(dlsTable:startDate:) methods instead.")
  }
  
}
