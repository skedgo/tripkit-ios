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
  
  /// Storage of information of what the cards are used for the segment at a
  /// specific index. There is one of these for every index, but not all are
  /// guarantueed to have cards, i.e., `cards` can be empty.
  struct SegmentCards {
    let segmentIndex: Int
    let cards: [TGCard]
    
    static func firstCardIndex(ofSegmentAt needle: Int, in haystack: [SegmentCards]) -> Int? {
      let index: (Int, Int?) = haystack.reduce( (0, nil) ) { acc, card in
        if acc.1 != nil {
          return acc
        } else if card.segmentIndex == needle {
          return (0, acc.0)
        } else {
          return (acc.0 + card.cards.count, nil)
        }
      }
      return index.1
    }
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
    guard let segmentIndex = segments.index(of: segment) else { preconditionFailure() }
    
    let segmentCards: [SegmentCards] = segments.enumerated().map {
      let cards = TKUITripModeByModeCard.config.builder.cards(for: $0.element, mapManager: mapManager)
      return SegmentCards(segmentIndex: $0.offset, cards: cards)
    }
    
    let cards = segmentCards.flatMap { $0.cards }
    let initialPage = SegmentCards.firstCardIndex(ofSegmentAt: segmentIndex, in: segmentCards)
    
    super.init(cards: cards, initialPage: initialPage ?? 0)
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
