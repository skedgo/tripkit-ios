//
//  TKUITripModeByModeViewController.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 29.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController

public protocol TKUITripModeByModeViewControllerDelegate: TGCardViewControllerDelegate {
}

public class TKUITripModeByModeViewController: TGCardViewController {
  
  public init(trip: Trip, initialPosition: TGCardPosition = .extended) {
    super.init(nibName: "TGCardViewController", bundle: Bundle(for: TGCardViewController.self))
    
    rootCard = TKUITripModeByModeCard(trip: trip, initialPosition: initialPosition)
    // TODO: Be the card's delegate and handle `modeByModeRequestsRebuildForNewSegments`
  }
  
  public init(startingOn segment: TKSegment, mode: TKUISegmentMode = .onSegment, initialPosition: TGCardPosition = .extended) {
    super.init(nibName: "TGCardViewController", bundle: Bundle(for: TGCardViewController.self))
    
    rootCard = try! TKUITripModeByModeCard(startingOn: segment, mode: mode, initialPosition: initialPosition)
    // TODO: Be the card's delegate and handle `modeByModeRequestsRebuildForNewSegments`
  }
  
  required public init(coder aDecoder: NSCoder) {
    fatalError("Use the `init(trip:)` or `init(startingOn:) methods instead.")
  }
  
}
