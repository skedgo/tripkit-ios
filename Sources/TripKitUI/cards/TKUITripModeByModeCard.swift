//
//  TKUITripModeByModeCard.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

import RxSwift
import RxCocoa
import TGCardViewController

import TripKit

public protocol TKUITripModeByModeCardDelegate {

  func modeByModeCard(_ card: TKUITripModeByModeCard, updatedTrip trip: Trip)
  
}

public class TKUITripModeByModeCard: TGPageCard {
  
  public typealias TripStartedActionHandler = (TKUITripModeByModeCard, Trip) -> Void
  
  enum Error: Swift.Error {
    case segmentTripDoesNotMatchMapManager
    case segmentHasNoTrip
  }
  
  /// Storage of information of what the cards are used for the segment at a
  /// specific index. There is one of these for every index, but not all are
  /// guarantueed to have cards, i.e., `cards` can be empty.
  fileprivate struct SegmentCardsInfo {
    let segmentIndex: Int
    let segmentIdentifier: String?
    let segmentMode: TKUISegmentMode
    let cards: [(TGCard, TKUISegmentMode)]
    let cardsRange: Range<Int>
    
    /// What's the indices of the cards for the provided `segment.index`,
    /// if all the cards in the haystack are next to each other?
    static func cardIndices(ofSegmentAt needle: Int, in haystack: [SegmentCardsInfo]) -> Range<Int>? {
      return haystack.first { $0.segmentIndex == needle }?.cardsRange
    }
    
    static func cardIndex(ofSegmentAt needle: Int, mode: TKUISegmentMode, in haystack: [SegmentCardsInfo]) -> Array<Int>.Index? {
      guard let segmentCardIndices = cardIndices(ofSegmentAt: needle, in: haystack) else { return nil }
      
      guard
        let segmentInfo = haystack.first(where: { $0.segmentIndex == needle }),
        let matchingModeIndex = segmentInfo.cards.firstIndex(where: { $0.1 == mode })
        else { return segmentCardIndices.lowerBound }
      
      return segmentCardIndices.lowerBound + matchingModeIndex
    }
    
    /// What's the indices of the cards for the provided `segment.segmentIdentifier`,
    /// if all the cards in the haystack are next to each other?
    static func cardIndices(ofSegmentWithIdentifier needle: String, in haystack: [SegmentCardsInfo]) -> Range<Int>? {
      return haystack.first { $0.segmentIdentifier == needle  }?.cardsRange
    }
    
    /// What's `SegmentCardsInfo` of the card at the provided index, if all the
    /// cards in the haystack are next to each otehr?
    static func cardsInfo(ofCardAtIndex needle: Int, in haystack: [SegmentCardsInfo]) -> SegmentCardsInfo? {
      return haystack.first { $0.cardsRange.contains(needle) }
    }
  }
  
  public static var config = Configuration.empty
  
  /// An action handler that is called when the mode by mode card is presented. The
  /// first parameters is the mode by mode card launched, while the second is the
  /// trip whose segments are presented by the mode by mode card.
  public var tripStartedHandler: TripStartedActionHandler?
    
  public var modeByModeDelegate: TKUITripModeByModeCardDelegate?
  
  private let viewModel: TKUITripModeByModeViewModel
  
  private let segmentCards: [SegmentCardsInfo]
  
  private var headerView: TKUITripModeByModeHeader? {
    headerAccessoryView as? TKUITripModeByModeHeader
  }

  private let tripMapManager: TKUITripMapManager
  
  private let disposeBag = DisposeBag()

  /// Constructs a page card configured for displaying the segments on a
  /// mode-by-mode basis of a trip.
  ///
  /// - Parameter segment: Segment to focus on first
  public init(startingOn segment: TKSegment, mode: TKUISegmentMode = .getReady, mapManager: TKUITripMapManager? = nil, initialPosition: TGCardPosition = .peaking) throws {
    guard let trip = segment.trip else {
      throw Error.segmentHasNoTrip
    }
    if let mapTrip = mapManager?.trip, segment.trip != mapTrip {
      throw Error.segmentTripDoesNotMatchMapManager
    }
    
    let viewModel = TKUITripModeByModeViewModel(trip: trip)
    self.viewModel = viewModel
    
    let tripMapManager = mapManager ?? TKUITripMapManager(trip: trip)
    self.tripMapManager = tripMapManager
    
    let builder = TKUITripModeByModeCard.config.builder
    let cardSegments = trip.segments(with: .inDetails)
    self.segmentCards = cardSegments.reduce( ([SegmentCardsInfo](), 0) ) { previous, segment in
      let identifier: String
      if let id = builder.cardIdentifier(for: segment) {
        identifier = id
      } else {
        assertionFailure("Make sure your TKUITripModeByModePageBuilder returns an identifier for every segment that gets a card.")
        identifier = segment.selectionIdentifier ?? ""
      }
      let cards = builder.cards(
        for: segment,
        mapManager: tripMapManager
      )
      let range = previous.1 ..< previous.1 + cards.count
      let info = SegmentCardsInfo(segmentIndex: segment.index, segmentIdentifier: identifier, segmentMode: mode, cards: cards, cardsRange: range)
      return (previous.0 + [info], range.upperBound)
    }.0

    let initialPage = SegmentCardsInfo.cardIndex(ofSegmentAt: segment.index, mode: mode, in: segmentCards) ?? 0
    
    let cards = segmentCards.flatMap { $0.cards.map { $0.0 } }
    let actualInitialPage = min(initialPage, cards.count - 1)
    super.init(cards: cards, initialPage: actualInitialPage, initialPosition: initialPosition)

    let headerView = TKUITripModeByModeHeader.newInstance()
    headerView.configure(trip: trip, selecting: segment.index)
    headerView.tapHandler = { [weak self] in self?.selectSegment(index: $0) }
    headerView.actionHandler = { [weak self] in self?.triggerPrimaryAction() }
    self.headerAccessoryView = headerView
    
    // Little hack for starting with selecting the first page on the map, too
    didMoveToPage(index: actualInitialPage)

    tripMapManager.attributionDisplayer = { [weak self] sources, sender in
      let displayer = TKUIAttributionTableViewController(attributions: sources)
      self?.controller?.present(displayer, inNavigator: true, preferredStyle: .popover, sender: sender)
    }
  }
  
  public convenience init(mapManager: TKUITripMapManager) {
    guard let first = mapManager.trip.segments.first else { preconditionFailure() }
    try! self.init(startingOn: first, mapManager: mapManager)
  }
  
  public convenience init(trip: Trip, initialPosition: TGCardPosition = .peaking) {
    guard let first = trip.segments.first else { preconditionFailure() }
    try! self.init(startingOn: first, initialPosition: initialPosition)
  }
  
  public override func didBuild(cardView: TGCardView?, headerView: TGHeaderView?) {
    super.didBuild(cardView: cardView, headerView: headerView)
    
    if let pageHeader = headerView, let modeByModeHeader = self.headerView {
      pageHeader.cornerRadius = 0
      let widthConstraint = modeByModeHeader.widthAnchor.constraint(equalTo: pageHeader.widthAnchor, constant: -16)
      widthConstraint.priority = .required
      widthConstraint.isActive = true
    }
    
    tripStartedHandler?(self, viewModel.trip)
    
    viewModel.realTimeUpdate
      .drive(onNext: { [unowned self] progress in
        guard case .updated(let updatedTrip) = progress else { return }
        self.reflectUpdates(of: updatedTrip)
        self.modeByModeDelegate?.modeByModeCard(self, updatedTrip: updatedTrip)
      })
      .disposed(by: disposeBag)
    
    NotificationCenter.default.rx
      .notification(.TKUIMapManagerSelectionChanged, object: tripMapManager)
      .map { $0.userInfo?["selection"] as? String }
      .filter { $0 != nil}
      .map { $0! }
      .observe(on: MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] in self?.reactToMapSelectionChange($0) })
      .disposed(by: disposeBag)
  }
  
  public override func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
    
    tripMapManager.annotationSelectionEnabled = true

    TKUIEventCallback.handler(.cardAppeared(self))
    if let controller = self.controller {
      TKUIEventCallback.handler(.tripSelected(viewModel.trip, controller: controller, disposeBag))
    }
  }
  
  public override func didMoveToPage(index: Int) {
    super.didMoveToPage(index: index)
   
    guard 
      let cardsInfo = SegmentCardsInfo.cardsInfo(ofCardAtIndex: index, in: segmentCards),
      let headerView
    else { assertionFailure(); return }
    let selectedHeaderIndex = headerView.segmentIndices.firstIndex { $0 >= cardsInfo.segmentIndex } // segment on card might not be in header
    headerView.segmentsView?.selectSegment(atIndex: selectedHeaderIndex ?? 0)
    
    if let segment = tripMapManager.trip.segments.first(where: { Self.config.builder.cardIdentifier(for: $0) == cardsInfo.segmentIdentifier }) {
      let offset = index - cardsInfo.cardsRange.lowerBound
      let mode = cardsInfo.cards[offset].1
      tripMapManager.show(segment, animated: true, mode: mode)
    }
  }
  
  private func selectSegment(index: Int) {
    guard let cardIndices = SegmentCardsInfo.cardIndices(ofSegmentAt: index, in: segmentCards)
      else { assertionFailure(); return }
    
    let target: Int
    if cardIndices.contains(currentPageIndex), cardIndices.count > 1 {
      target = (currentPageIndex == cardIndices.upperBound - 1)
        ? cardIndices.lowerBound
        : currentPageIndex + 1
    } else if !cardIndices.contains(currentPageIndex) {
      target = cardIndices.lowerBound
    } else {
      return // Only a single card which is already selected
    }
    move(to: target)
  }
  
  private func triggerPrimaryAction() {
    let trip = viewModel.trip
    guard
      let primaryAction = TKUITripOverviewCard.config.tripActionsFactory?(trip).first(where: { $0.priority >= TKUITripOverviewCard.DefaultActionPriority.book.rawValue }),
      let view = self.controller?.view
    else { return }
    
    let _ = primaryAction.handler(primaryAction, self, trip, view)
  }
  
  public func offsetToReach(mode: TKUISegmentMode, in segment: TKSegment) -> Int? {
    guard
      let segmentInfo = segmentCards.first(where: { $0.segmentIndex == segment.index }),
      let modeIndex = segmentInfo.cards.firstIndex(where: { $0.1 == mode })
      else { return nil }
    
    return modeIndex
  }
  
  public func shows(tripURL: URL, tripID: String?) -> Bool {
    return viewModel.trip.matches(tripURL: tripURL, tripID: tripID)
  }
  
  deinit {
    let cards = self.cards
    DispatchQueue.main.async {
      TKUITripModeByModeCard.config.builder.cleanUp(existingCards: cards)
    }
  }
  
}

// MARK: - Map interaction

extension TKUITripModeByModeCard {
  
  private func reactToMapSelectionChange(_ identifier: String) {
    // When the map selection changed, we potentially have several candidate
    // cards. We then want to move to the closer index, i.e., the last if we
    // previously showed a later card, or the first if we previously showed
    // an earlier card.
    
    guard
      let indices = SegmentCardsInfo.cardIndices(ofSegmentWithIdentifier: identifier, in: segmentCards)
      else { return }
    if currentPageIndex < indices.lowerBound {
      move(to: indices.lowerBound)
    } else if currentPageIndex >= indices.upperBound {
      move(to: indices.upperBound - 1)
    }
  }
  
}

// MARK: - Real-time update

extension TKUITripModeByModeCard {
  
  private func segmentsMatch(_ newSegments: [TKSegment]) -> Bool {
    let oldTemplates = segmentCards.map { $0.segmentIdentifier }
    let newTemplates = newSegments.compactMap(Self.config.builder.cardIdentifier)
    return oldTemplates == newTemplates
  }
  
  /// Call this whenver the trip object did change to reflect those changes in the UI
  ///
  /// - Parameter trip: The trip; fires an assert if the trip changed to what's on the map.
  private func reflectUpdates(of trip: Trip) {
    assert(trip == tripMapManager.trip, "Uh-oh, trip changed!")
    
    let cardSegments = trip.segments(with: .inDetails)
    
    if segmentsMatch(cardSegments) {
      // Update the header
      headerView?.update(trip: trip)
      
      // Important to update the map, too, as template hash codes can change
      // an the map uses those for selection handling
      (mapManager as? TKUITripMapManager)?.refresh(with: trip)
      
    } else {
      // We use the index here as the identifier would have changed. The index
      // gives us a good guess for finding the corresponding segment in the new
      // trip.
      let cardInfo = SegmentCardsInfo.cardsInfo(ofCardAtIndex: currentPageIndex, in: segmentCards)
      let newSegment = cardSegments.first(where: { $0.index == cardInfo?.segmentIndex }) ?? cardSegments.first!
      
      do {
        let newCard = try TKUITripModeByModeCard(
          startingOn: newSegment,
          mapManager: mapManager as? TKUITripMapManager
        )
        newCard.style = self.style
        newCard.modeByModeDelegate = self.modeByModeDelegate
        
        if let cardInfo = cardInfo, let offset = offsetToReach(mode: cardInfo.segmentMode, in: newSegment) {
          controller?.swap(for: newCard, animated: true, onCompletion: {
            newCard.move(to: newCard.currentPageIndex + offset)
          })
        } else {
          controller?.swap(for: newCard, animated: true)
        }
      } catch {
        TKLog.warn("Could not rebuild due to \(error)")
      }
    }
  }
  
}
