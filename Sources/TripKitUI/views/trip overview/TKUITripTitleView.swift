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
  
  static func newInstance() -> TKUITripTitleView {
    return Bundle.tripKitUI.loadNibNamed("TKUITripTitleView", owner: self, options: nil)?.first as! TKUITripTitleView
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    
    backgroundColor = .tkBackground

    timeTitleLabel.text = nil
    timeSubtitleLabel.text = nil

    dismissButton.setImage(TGCard.closeButtonImage, for: .normal)
    dismissButton.setTitle(nil, for: .normal)
    dismissButton.accessibilityLabel = Loc.Close
  }
  
  func update(preferredContentSizeCategory: UIContentSizeCategory) {
    timeStack.axis = preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
  }

}

// MARK: - Configure

extension TKUITripTitleView {
  func configure(with model: TKUITripCell.Model) {
    timeTitleLabel.text = model.hideExactTimes ? nil : TKUITripCell.Formatter.primaryTimeString(departure: model.departure, arrival: model.arrival, departureTimeZone: model.departureTimeZone, arrivalTimeZone: model.arrivalTimeZone, focusOnDuration: model.focusOnDuration, isArriveBefore: model.isArriveBefore)
    timeTitleLabel.font = TKStyleManager.customFont(forTextStyle: .body)
    timeTitleLabel.textColor = .tkLabelPrimary

    timeSubtitleLabel.text = model.hideExactTimes ? nil : TKUITripCell.Formatter.secondaryTimeString(departure: model.departure, arrival: model.arrival, departureTimeZone: model.departureTimeZone, arrivalTimeZone: model.arrivalTimeZone, focusOnDuration: model.focusOnDuration, isArriveBefore: model.isArriveBefore)
    timeSubtitleLabel.font = TKStyleManager.customFont(forTextStyle: .body)
    timeSubtitleLabel.textColor = .tkLabelSecondary

    segmentView.isCanceled = model.isCancelled
    segmentView.configure(model.segments)
    
    let alpha: CGFloat = model.showFaded ? 0.2 : 1
    timeTitleLabel.alpha = alpha
    timeSubtitleLabel.alpha = alpha
    
    accessibilityLabel = model.accessibilityLabel
  }
}
