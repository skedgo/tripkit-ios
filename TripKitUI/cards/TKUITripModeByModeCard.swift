//
//  TKUITripModeByModeCard.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController

public class TKUITripModeByModeCard: TGPageCard {
  
  enum Error: Swift.Error {
    case segmentTripDoesNotMatchMapManager
  }
  
  public static var config = Configuration.empty

  /// Constructs a page card configured for displaying the segments on a
  /// mode-by-mode basis of a trip.
  ///
  /// - Parameter segment: Segment to focus on first
  public init(startingOn segment: TKSegment, mapManager: TKUITripMapManager) throws {
    guard segment.trip == mapManager.trip else {
      throw Error.segmentTripDoesNotMatchMapManager
    }
    
    let segments = segment.trip.segments
    guard let index = segments.index(of: segment) else { preconditionFailure() }
    
    let cards = segments.flatMap { TKUITripModeByModeCard.config.builder.cards(for: $0, mapManager: mapManager) }
    
    super.init(cards: cards, initialPage: index)
  }
  
  public convenience init(mapManager: TKUITripMapManager) {
    guard let first = mapManager.trip.segments.first else { preconditionFailure() }
    try! self.init(startingOn: first, mapManager: mapManager)
  }
  
  required init?(coder: NSCoder) {
    // TODO: Implement to support state-restoration
    return nil
  }
  
}
