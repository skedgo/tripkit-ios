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
  fileprivate struct SegmentCards {
    let segmentIndex: Int
    let cards: [TGCard]
    
    /// What's the index of the first card for the provided `segment.index`,
    /// if all the cards in the haystack are next to each other?
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
    
    /// What's `segment.index` of the card at the provided index, if all the
    /// cards in the haystack are next to each otehr?
    static func segmentIndex(ofCardAtIndex needle: Int, in haystack: [SegmentCards]) -> Int {
      let index: (Int, Int?) = haystack.reduce( (0, nil) ) { acc, card in
        guard acc.1 == nil else { return acc }
        let currentMax = acc.0 + card.cards.count
        if needle < currentMax {
          return (0, card.segmentIndex)
        } else {
          return (currentMax, nil)
        }
      }
      return index.1 ?? 0
    }
  }
  
  public static var config = Configuration.empty
  
  private let segmentCards: [SegmentCards]
  private let headerSegmentIndices: [Int]
  
  private var segmentView: TKUITripSegmentsView? {
    return headerAccessoryView as? TKUITripSegmentsView
  }

  private let feedbackGenerator = UISelectionFeedbackGenerator()

  private let tripMapManager: TKUITripMapManager

  /// Constructs a page card configured for displaying the segments on a
  /// mode-by-mode basis of a trip.
  ///
  /// - Parameter segment: Segment to focus on first
  public init(startingOn segment: TKSegment, mapManager: TKUITripMapManager? = nil) throws {
    if let mapTrip = mapManager?.trip, segment.trip != mapTrip {
      throw Error.segmentTripDoesNotMatchMapManager
    }
    
    let tripMapManager = mapManager ?? TKUITripMapManager(trip: segment.trip)
    self.tripMapManager = tripMapManager
    
    // TODO: Segment.index works generally, but not for the first and last
    //   card, i.e., departure and arrival as those don't have an index
    
    let cardSegments = segment.trip.segments(with: .inDetails).compactMap { $0 as? TKSegment }
    
    let segmentCards: [SegmentCards] = cardSegments.map {
      let cards = TKUITripModeByModeCard.config.builder.cards(for: $0, mapManager: tripMapManager)
      return SegmentCards(segmentIndex: $0.index, cards: cards)
    }
    let cards = segmentCards.flatMap { $0.cards }
    let initialPage = SegmentCards.firstCardIndex(ofSegmentAt: segment.index, in: segmentCards)
    self.segmentCards = segmentCards

    let headerSegments = segment.trip.segments(with: .inSummary).compactMap { $0 as? TKSegment }
    self.headerSegmentIndices = headerSegments.map { $0.index }
    
    super.init(cards: cards, initialPage: initialPage ?? 0)

    self.headerAccessoryView = buildSegmentsView(segments: headerSegments, selecting: segment.index)
    
    // Little hack for starting with selecting the first page on the map, too
    didMoveToPage(index: initialPage ?? 0)
  }
  
  public convenience init(mapManager: TKUITripMapManager) {
    guard let first = mapManager.trip.segments.first else { preconditionFailure() }
    try! self.init(startingOn: first, mapManager: mapManager)
  }
  
  public convenience init(trip: Trip) {
    guard let first = trip.segments.first else { preconditionFailure() }
    try! self.init(startingOn: first)
  }

  
  required init?(coder: NSCoder) {
    // TODO: Implement to support state-restoration
    return nil
  }
  
  public override func didMoveToPage(index: Int) {
    super.didMoveToPage(index: index)
   
    guard let segmentsView = self.headerAccessoryView as? TKUITripSegmentsView else { return }
    let segmentIndex = SegmentCards.segmentIndex(ofCardAtIndex: index, in: segmentCards)
    let selectedHeaderIndex = headerSegmentIndices.firstIndex { $0 >= segmentIndex } // exact segment might not be available!
    segmentsView.select(segmentAtIndex: selectedHeaderIndex ?? 0)
    
    if let segment = tripMapManager.trip.segments.first(where: { $0.index == segmentIndex }) {
      tripMapManager.show(segment, animated: true)
    }

  }
  
}

// MARK: - Segments view in header

extension TKUITripModeByModeCard {
  
  private func buildSegmentsView(segments: [TKSegment], selecting index: Int) -> TKUITripSegmentsView {
    let selectedHeaderIndex = headerSegmentIndices.firstIndex { $0 >= index } // exact segment might not be available!

    let segmentsView = TKUITripSegmentsView(frame: .zero)
    segmentsView.darkTextColor  = .white
    segmentsView.lightTextColor = .lightGray
    segmentsView.configure(forSegments: segments, allowSubtitles: true, allowInfoIcons: false)
    segmentsView.select(segmentAtIndex: selectedHeaderIndex ?? 0)

    let tapper = UITapGestureRecognizer(target: self, action: #selector(segmentTapped))
    segmentsView.addGestureRecognizer(tapper)
    
    feedbackGenerator.prepare()
    
    return segmentsView
  }
  
  @objc
  private func segmentTapped(_ recognizer: UITapGestureRecognizer) {
    guard let segmentsView = self.segmentView
      else { assertionFailure(); return }
    
    let x = recognizer.location(in: segmentsView).x
    let headerIndex = segmentsView.segmentIndex(atX: x)
    
    let segmentIndex = headerSegmentIndices[headerIndex]
    guard
      let cardIndex = SegmentCards.firstCardIndex(ofSegmentAt: segmentIndex, in: segmentCards),
      cardIndex != currentPageIndex
      else { return }
    
    move(to: cardIndex)
    
    feedbackGenerator.selectionChanged()
    feedbackGenerator.prepare()
  }
  
}
