//
//  TKUITripModeByModeHeader.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 8/8/2024.
//  Copyright © 2024 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

class TKUITripModeByModeHeader: UIView {
  
  private let feedbackGenerator = UISelectionFeedbackGenerator()
  
  private(set) var segmentIndices: [Int] = []
  
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var subtitleLabel: UILabel!
  
  @IBOutlet var segmentsView: TKUITripSegmentsView!
  @IBOutlet var actionButton: UIButton!
  
  var tapHandler: (Int) -> Void = { _ in }
  
  static func newInstance() -> TKUITripModeByModeHeader {
    let view = Bundle(for: self).loadNibNamed("TKUITripModeByModeHeader", owner: self, options: nil)?.first as! TKUITripModeByModeHeader
    return view
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()

    segmentsView.darkTextColor  = .tkLabelPrimary
    segmentsView.lightTextColor = .tkLabelSecondary

    titleLabel.text = ""
    titleLabel.textColor = .tkLabelSecondary
    titleLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
    
    subtitleLabel.text = ""
    subtitleLabel.textColor = .tkLabelSecondary
    subtitleLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
    subtitleLabel.isHidden = true
  }
  
  func configure(trip: Trip, selecting index: Int) {
    let segments = trip.headerSegments
    segmentIndices = segments.map(\.index)
    
    let selectedHeaderIndex = segmentIndices.firstIndex { $0 >= index } // exact segment might not be available!
    segmentsView.configure(segments, allowInfoIcons: false)
    segmentsView.selectSegment(atIndex: selectedHeaderIndex ?? 0)
    
    let tapper = UITapGestureRecognizer(target: self, action: #selector(segmentTapped))
    segmentsView.addGestureRecognizer(tapper)
    
    titleLabel.text = Self.headerTimeText(for: trip)
    
    // TODO: Add subtitle
    
    // TODO: Add action button
    
    feedbackGenerator.prepare()
  }
  
  func update(trip: Trip) {
    segmentsView.configure(trip.headerSegments, allowInfoIcons: false)
    titleLabel.text = Self.headerTimeText(for: trip)
  }
  
  @objc
  private func segmentTapped(_ recognizer: UITapGestureRecognizer) {
    let x = recognizer.location(in: segmentsView).x
    let headerIndex = segmentsView.segmentIndex(atX: x)
    
    let segmentIndex = segmentIndices[headerIndex]
    tapHandler(segmentIndex)
    
    feedbackGenerator.selectionChanged()
  }
}

extension Trip {
  fileprivate var headerSegments: [TKSegment] { segments(with: .inSummary) }
}

extension TKUITripModeByModeHeader {
  
  private static func headerTimeText(for trip: Trip) -> String {
    guard !trip.hideExactTimes else { return "" }
    
    // TODO: Use same logic as TripOverviewCard
    let departure = TKStyleManager.timeString(trip.departureTime, for: trip.departureTimeZone)
    let arrival   = TKStyleManager.timeString(trip.arrivalTime, for: trip.arrivalTimeZone ?? trip.departureTimeZone, relativeTo: trip.departureTimeZone)
    return "\(departure) - \(arrival)"
  }

}
