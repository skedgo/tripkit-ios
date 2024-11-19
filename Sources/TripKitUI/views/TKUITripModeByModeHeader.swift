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
  var actionHandler: () -> Void = {}
  
  static func newInstance() -> TKUITripModeByModeHeader {
    let view = Bundle.tripKitUI.loadNibNamed("TKUITripModeByModeHeader", owner: self, options: nil)?.first as! TKUITripModeByModeHeader
    return view
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()

    segmentsView.darkTextColor  = .tkLabelPrimary
    segmentsView.lightTextColor = .tkLabelSecondary

    titleLabel.text = ""
    titleLabel.textColor = .tkLabelPrimary
    titleLabel.font = TKStyleManager.customFont(forTextStyle: .body)
    
    subtitleLabel.text = ""
    subtitleLabel.textColor = .tkLabelSecondary
    subtitleLabel.font = TKStyleManager.customFont(forTextStyle: .body)
    
    if #available(iOS 15.0, *) {
      var config = UIButton.Configuration.filled()
      config.titleTextAttributesTransformer = .init { incoming in
        var outgoing = incoming
        outgoing.font = TKStyleManager.semiboldCustomFont(forTextStyle: .subheadline)
        return outgoing
      }
      config.cornerStyle = .capsule
      actionButton.configuration = config
    } else {
      actionButton.titleLabel?.font = TKStyleManager.semiboldCustomFont(forTextStyle: .subheadline)
    }
  }
  
  func configure(trip: Trip, selecting index: Int) {
    let segments = trip.headerSegments
    segmentIndices = segments.map(\.index)
    
    let selectedHeaderIndex = segmentIndices.firstIndex { $0 >= index } // exact segment might not be available!
    segmentsView.configure(segments, allowInfoIcons: false)
    segmentsView.selectSegment(atIndex: selectedHeaderIndex ?? 0)
    
    let tapper = UITapGestureRecognizer(target: self, action: #selector(segmentTapped))
    segmentsView.addGestureRecognizer(tapper)
    
    update(trip: trip)
    
    feedbackGenerator.prepare()
  }
  
  func update(trip: Trip) {
    let cellModel = TKUITripCell.Model(trip, allowFading: false)
    titleLabel.text = cellModel.primaryTimeString
    subtitleLabel.text = cellModel.secondaryTimeString
    
    if let action = cellModel.primaryAction {
      actionButton.setTitle(action, for: .normal)
      actionButton.isHidden = false
    } else {
      actionButton.setTitle("", for: .normal)
      actionButton.isHidden = true
    }
  }
  
  @objc
  private func segmentTapped(_ recognizer: UITapGestureRecognizer) {
    let x = recognizer.location(in: segmentsView).x
    let headerIndex = segmentsView.segmentIndex(atX: x)
    
    let segmentIndex = segmentIndices[headerIndex]
    tapHandler(segmentIndex)
    
    feedbackGenerator.selectionChanged()
  }
  
  @IBAction func buttonTapped(_ sender: Any) {
    actionHandler()
  }
  
}

extension Trip {
  fileprivate var headerSegments: [TKSegment] { segments(with: .inSummary) }
}
