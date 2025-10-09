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

  @IBOutlet weak var topLevelLeadingConstraint: NSLayoutConstraint!
  @IBOutlet private weak var dismissButtonTrailingConstraint: NSLayoutConstraint!
  @IBOutlet private weak var dismissButtonTopConstraint: NSLayoutConstraint!

  static func newInstance() -> TKUITripTitleView {
    return Bundle.tripKitUI.loadNibNamed("TKUITripTitleView", owner: self, options: nil)?.first as! TKUITripTitleView
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    
    if #available(iOS 26.0, *) {
      topLevelLeadingConstraint.constant = 22
      dismissButtonTrailingConstraint.constant = 18
      dismissButtonTopConstraint.constant = 2
    } else {
      topLevelLeadingConstraint.constant = 16
      dismissButtonTrailingConstraint.constant = 4
      dismissButtonTopConstraint.constant = -11
    }

    backgroundColor = .tkBackground

    timeTitleLabel.text = nil
    timeSubtitleLabel.text = nil

    TGCard.configureCloseButton(dismissButton)
    dismissButton.accessibilityLabel = Loc.Close
  }
  
  func update(preferredContentSizeCategory: UIContentSizeCategory) {
    timeStack.axis = preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
  }

}

// MARK: - Configure

extension TKUITripTitleView {
  func configure(with model: TKUITripCell.Model) {
    if #available(iOS 26.0, *) {
      timeTitleLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .title2)
      timeSubtitleLabel.font = TKStyleManager.customFont(forTextStyle: .title2)
    } else {
      timeTitleLabel.font = TKStyleManager.customFont(forTextStyle: .body)
      timeSubtitleLabel.font = TKStyleManager.customFont(forTextStyle: .body)
    }
    
    timeTitleLabel.text = model.primaryTimeString
    timeTitleLabel.textColor = .tkLabelPrimary

    timeSubtitleLabel.text = model.secondaryTimeString
    timeSubtitleLabel.textColor = .tkLabelSecondary

    segmentView.isCanceled = model.isCancelled
    segmentView.configure(model.segments)
    
    let alpha: CGFloat = model.showFaded ? 0.2 : 1
    timeTitleLabel.alpha = alpha
    timeSubtitleLabel.alpha = alpha
    
    accessibilityLabel = model.accessibilityLabel
  }
}
