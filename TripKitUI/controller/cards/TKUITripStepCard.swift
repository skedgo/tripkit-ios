//
//  TKUITripStepCard.swift
//  TripKit
//
//  Created by Adrian Schoenig on 11/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController

#if TK_NO_MODULE
#else
  import TripKit
#endif

extension TGPageCard {
  
  /// Constructs a page card configured for displaying the alternative trips
  /// of a request.
  ///
  /// - Parameter trip: Trip to focus on first
  public convenience init(forModeByModeHighlighting segment: TKSegment, mapManager: TKUITripMapManager) {
    precondition(segment.trip == mapManager.trip)
    
    let segments = segment.trip.segments()
    guard let index = segments.index(of: segment) else { preconditionFailure() }
    
    let cards = segments.map { TKUITripStepCard(for: $0, mapManager: mapManager) }
    
    // TODO: Give some meaningful title?
    self.init(title: "Trip", cards: cards, initialPage: index)
  }

  
  public convenience init(forModeByModeWith mapManager: TKUITripMapManager) {
    guard let first = mapManager.trip.segments().first else { preconditionFailure() }
    self.init(forModeByModeHighlighting: first, mapManager: mapManager)
  }
  
}


class TKUITripStepCard: TGPlainCard {
  
  // TODO: Move to a card model
  
  let segment: TKSegment
  
  var tripMapManager: TKUITripMapManager {
    guard let tripper = mapManager as? TKUITripMapManager else { preconditionFailure() }
    return tripper
  }
  
  init(for segment: TKSegment, mapManager: TKUITripMapManager) {
    self.segment = segment
    
    super.init(title: segment.title ?? "", mapManager: mapManager)
  }
  
  override func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
    
    // FIXME: Move to a delegate
    // SGScreenshotFeedback.sharedInstance.object = segment
    
    tripMapManager.show(segment, animated: animated)
  }
  
}


