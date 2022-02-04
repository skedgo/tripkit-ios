//
//  TKUITripTitleView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 3/2/2022.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TGCardViewController

import TripKit

class TKUITripTitleView: UIView {
  
  @IBOutlet weak var timeStack: UIStackView!
  @IBOutlet weak var timeTitleLabel: TKUIStyledLabel!
  @IBOutlet weak var timeSubtitleLabel: TKUIStyledLabel!
  @IBOutlet weak var segmentView: TKUITripSegmentsView!

  @IBOutlet weak var dismissButton: UIButton!
  
  private var formatter: TKUITripCell.Formatter? = nil

  static func newInstance() -> TKUITripTitleView {
    return Bundle(for: TKUITripTitleView.self).loadNibNamed("TKUITripTitleView", owner: self, options: nil)?.first as! TKUITripTitleView
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    
    backgroundColor = .tkBackground
    
    formatter = .init()
    formatter?.primaryColor = .tkLabelPrimary
    formatter?.primaryFont = TKStyleManager.customFont(forTextStyle: .body)
    formatter?.secondaryColor = .tkLabelSecondary
    formatter?.secondaryFont = TKStyleManager.customFont(forTextStyle: .body)

    timeTitleLabel.text = nil
    timeSubtitleLabel.text = nil

    dismissButton.setImage(TGCard.closeButtonImage, for: .normal)
    dismissButton.setTitle(nil, for: .normal)
    dismissButton.accessibilityLabel = Loc.Close
  }

}

// MARK: - Configure

extension TKUITripTitleView {
  func configure(with model: TKUITripCell.Model) {
    guard let formatter = self.formatter else { return }

    timeTitleLabel.attributedText = model.hideExactTimes ? nil : formatter.primaryTimeString(departure: model.departure, arrival: model.arrival, departureTimeZone: model.departureTimeZone, arrivalTimeZone: model.arrivalTimeZone, focusOnDuration: model.focusOnDuration, isArriveBefore: model.isArriveBefore)
    
    timeSubtitleLabel.attributedText = model.hideExactTimes ? nil : formatter.secondaryTimeString(departure: model.departure, arrival: model.arrival, departureTimeZone: model.departureTimeZone, arrivalTimeZone: model.arrivalTimeZone, focusOnDuration: model.focusOnDuration, isArriveBefore: model.isArriveBefore)
    
    segmentView.isCanceled = model.isCancelled
    segmentView.configure(model.segments)
    
    let alpha: CGFloat = model.showFaded ? 0.2 : 1
    timeTitleLabel.alpha = alpha
    timeSubtitleLabel.alpha = alpha
    
    accessibilityLabel = model.accessibilityLabel
  }
}
