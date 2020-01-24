//
//  TKUITripModeByModeCard.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import TGCardViewController

public protocol TKUITripModeByModeCardDelegate: class {
  func modeByModeRequestsRebuildForNewSegments(_ card: TKUITripModeByModeCard, trip: Trip, currentSegment: TKSegment)
}

public class TKUITripModeByModeCard: TGPageCard {
  
  enum Error: Swift.Error {
    case segmentTripDoesNotMatchMapManager
    case segmentHasNoTrip
  }
  
  /// Storage of information of what the cards are used for the segment at a
  /// specific index. There is one of these for every index, but not all are
  /// guarantueed to have cards, i.e., `cards` can be empty.
  fileprivate struct SegmentCardsInfo {
    let segmentIndex: Int
    let segmentIdentifier: String
    let cards: [(TGCard, TKUISegmentMode)]
    let cardsRange: Range<Int>
    
    /// What's the indices of the cards for the provided `segment.index`,
    /// if all the cards in the haystack are next to each other?
    static func cardIndices(ofSegmentAt needle: Int, in haystack: [SegmentCardsInfo]) -> Range<Int>? {
      return haystack.first { $0.segmentIndex == needle }?.cardsRange
    }
    
    /// What's the indices of the cards for the provided `segment.selectionIdentifier`,
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
  
  public weak var modeByModeDelegate: TKUITripModeByModeCardDelegate?
  
  private let viewModel: TKUITripModeByModeViewModel
  
  private let segmentCards: [SegmentCardsInfo]
  private let headerSegmentIndices: [Int]
  
  private var headerSegmentsView: TKUITripSegmentsView? {
    return TKUITripModeByModeCard.findSubview(TKUITripSegmentsView.self, in: headerAccessoryView)
  }
  private var headerETALabel: UILabel? {
    return TKUITripModeByModeCard.findSubview(UILabel.self, in: headerAccessoryView)
  }

  private let feedbackGenerator = UISelectionFeedbackGenerator()

  private let tripMapManager: TKUITripMapManager
  
  private let disposeBag = DisposeBag()

  /// Constructs a page card configured for displaying the segments on a
  /// mode-by-mode basis of a trip.
  ///
  /// - Parameter segment: Segment to focus on first
  public init(startingOn segment: TKSegment, mode: TKUISegmentMode = .onSegment, mapManager: TKUITripMapManager? = nil, initialPosition: TGCardPosition = .peaking) throws {
    guard let trip = segment.trip else {
      throw Error.segmentHasNoTrip
    }
    if let mapTrip = mapManager?.trip, segment.trip != mapTrip {
      throw Error.segmentTripDoesNotMatchMapManager
    }
    
    self.viewModel = TKUITripModeByModeViewModel(trip: trip)
    
    let tripMapManager = mapManager ?? TKUITripMapManager(trip: trip)
    self.tripMapManager = tripMapManager
    
    let cardSegments = trip.segments(with: .inDetails).compactMap { $0 as? TKSegment }
    self.segmentCards = cardSegments.reduce( ([SegmentCardsInfo](), 0) ) { previous, segment in
      let cards = TKUITripModeByModeCard.config.builder.cards(for: segment, mapManager: tripMapManager)
      let range = previous.1 ..< previous.1 + cards.count
      let info = SegmentCardsInfo(segmentIndex: segment.index, segmentIdentifier: segment.selectionIdentifier!, cards: cards, cardsRange: range)
      return (previous.0 + [info], range.upperBound)
    }.0

    let headerSegments = trip.headerSegments
    self.headerSegmentIndices = headerSegments.map { $0.index }
    
    // TODO: Pick the correct one according to the mode, too
    let initialPage = SegmentCardsInfo.cardIndices(ofSegmentAt: segment.index, in: segmentCards)?.lowerBound ?? 0
    
    let cards = segmentCards.flatMap { $0.cards.map { $0.0 } }
    let actualInitialPage = min(initialPage, cards.count - 1)
    super.init(cards: cards, initialPage: actualInitialPage, initialPosition: initialPosition)

    self.headerAccessoryView = buildSegmentsView(segments: headerSegments, selecting: segment.index, trip: trip)
    
    // Little hack for starting with selecting the first page on the map, too
    didMoveToPage(index: actualInitialPage)
  }
  
  public convenience init(mapManager: TKUITripMapManager) {
    guard let first = mapManager.trip.segments.first else { preconditionFailure() }
    try! self.init(startingOn: first, mapManager: mapManager)
  }
  
  public convenience init(trip: Trip, initialPosition: TGCardPosition = .peaking) {
    guard let first = trip.segments.first else { preconditionFailure() }
    try! self.init(startingOn: first, initialPosition: initialPosition)
  }
  
  public override func didBuild(cardView: TGCardView, headerView: TGHeaderView?) {
    super.didBuild(cardView: cardView, headerView: headerView)
    
    viewModel.realTimeUpdate
      .drive(onNext: { [unowned self] progress in
        guard case .updated(let updatedTrip) = progress else { return }
        self.reflectUpdates(of: updatedTrip)
      })
      .disposed(by: disposeBag)
    
    viewModel.tripDidUpdate
      .emit(onNext: { [unowned self] in self.reflectUpdates(of: $0) })
      .disposed(by: disposeBag)

    
    NotificationCenter.default.rx
      .notification(.TKUIMapManagerSelectionChanged, object: tripMapManager)
      .map { $0.userInfo?["selection"] as? String }
      .filter { $0 != nil}
      .map { $0! }
      .subscribe(onNext: { [weak self] in self?.reactToMapSelectionChange($0) })
      .disposed(by: disposeBag)
  }

  
  required init?(coder: NSCoder) {
    // Implement this to support state-restoration
    return nil
  }
  
  public override func didMoveToPage(index: Int) {
    super.didMoveToPage(index: index)
   
    guard let cardsInfo = SegmentCardsInfo.cardsInfo(ofCardAtIndex: index, in: segmentCards)
      else { assertionFailure(); return }
    let selectedHeaderIndex = headerSegmentIndices.firstIndex { $0 >= cardsInfo.segmentIndex } // segment on card might not be in header
    headerSegmentsView?.select(segmentAtIndex: selectedHeaderIndex ?? 0)
    
    if let segment = tripMapManager.trip.segments.first(where: { $0.selectionIdentifier == cardsInfo.segmentIdentifier }) {
      let offset = index - cardsInfo.cardsRange.lowerBound
      let mode = cardsInfo.cards[offset].1
      tripMapManager.show(segment, animated: true, mode: mode)
    }
  }
  
}

// MARK: - Segments view in header

fileprivate extension Trip {
  var headerSegments: [TKSegment] {
    return segments(with: .inSummary).compactMap { $0 as? TKSegment }
  }
}

extension TKUITripModeByModeCard {
  
  private static func findSubview<V: UIView>(_ type: V.Type, in header: UIView?) -> V? {
    guard let stack = header as? UIStackView else { return nil }
    return stack.arrangedSubviews.compactMap { $0 as? V }.first
  }
  
  private static func headerTimeText(for trip: Trip) -> String {
    let departure = TKStyleManager.timeString(trip.departureTime, for: trip.departureTimeZone)
    let arrival   = TKStyleManager.timeString(trip.arrivalTime, for: trip.arrivalTimeZone ?? trip.departureTimeZone, relativeTo: trip.departureTimeZone)
    return "\(departure) - \(arrival)"
  }

  private func buildSegmentsView(segments: [TKSegment], selecting index: Int, trip: Trip) -> UIView {
    // the segments view
    let selectedHeaderIndex = headerSegmentIndices.firstIndex { $0 >= index } // exact segment might not be available!

    let segmentsView = TKUITripSegmentsView(frame: .zero)
    segmentsView.darkTextColor  = .tkLabelPrimary
    segmentsView.lightTextColor = .tkLabelSecondary
    segmentsView.configure(forSegments: segments, allowSubtitles: true, allowInfoIcons: false)
    segmentsView.select(segmentAtIndex: selectedHeaderIndex ?? 0)

    let tapper = UITapGestureRecognizer(target: self, action: #selector(segmentTapped))
    segmentsView.addGestureRecognizer(tapper)
    
    feedbackGenerator.prepare()
    
    // the label
    let label = UILabel()
    label.text = TKUITripModeByModeCard.headerTimeText(for: trip)
    label.textColor = .tkLabelSecondary
    label.font = TKStyleManager.customFont(forTextStyle: .footnote)
    label.textAlignment = .center
    
    // combine them
    let stack = UIStackView(arrangedSubviews: [segmentsView, label])
    stack.axis = .vertical
    stack.distribution = .fill
    
    return stack
  }
  
  @objc
  private func segmentTapped(_ recognizer: UITapGestureRecognizer) {
    guard let segmentsView = self.headerSegmentsView
      else { assertionFailure(); return }
    
    let x = recognizer.location(in: segmentsView).x
    let headerIndex = segmentsView.segmentIndex(atX: x)
    
    let segmentIndex = headerSegmentIndices[headerIndex]
    guard let cardIndices = SegmentCardsInfo.cardIndices(ofSegmentAt: segmentIndex, in: segmentCards)
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
    
    feedbackGenerator.selectionChanged()
    feedbackGenerator.prepare()
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
    // TODO: This should also change if something else about the segments
    //   such as if there are alerts inserted, which the builder might create
    //   cards for. So ideally, we should pass this to the builder.
    
    let oldTemplates = segmentCards.map { $0.segmentIdentifier }
    let newTemplates = newSegments.compactMap { $0.selectionIdentifier }
    return oldTemplates == newTemplates
  }
  
  /// Call this whenver the trip object did change to reflect those changes in the UI
  ///
  /// - Parameter trip: The trip; fires an assert if the trip changed to what's on the map.
  private func reflectUpdates(of trip: Trip) {
    assert(trip == tripMapManager.trip, "Uh-oh, trip changed!")
    
    let cardSegments = trip.segments(with: .inDetails).compactMap { $0 as? TKSegment }
    guard segmentsMatch(cardSegments) else {
      // We use the index here as the identifier would have changed. The index
      // gives us a good guess for finding the corresponding segment in the new
      // trip.
      let segmentIndex = SegmentCardsInfo.cardsInfo(ofCardAtIndex: currentPageIndex, in: segmentCards)?.segmentIndex
      let newSegment = cardSegments.first(where: { $0.index == segmentIndex }) ?? cardSegments.first!
      self.modeByModeDelegate?.modeByModeRequestsRebuildForNewSegments(self, trip: trip, currentSegment: newSegment)
      return
    }
    
    // Update segment view in header
    headerSegmentsView?.configure(forSegments: trip.headerSegments, allowSubtitles: true, allowInfoIcons: false)
    
    // Update ETA in header
    headerETALabel?.text = TKUITripModeByModeCard.headerTimeText(for: trip)
    
    // Also pass on generic updates, trip map manager will react itself
    TKUITripModeByModeCard.notifyOfUpdates(in: trip)
  }
  
}