//
//  TKUIServiceTitleView.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 19.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TGCardViewController

import TripKit

class TKUIServiceTitleView: UIView {

  @IBOutlet weak var serviceTitleLabel: TKUIStyledLabel!
  
  @IBOutlet weak var serviceImageView: UIImageView!
  @IBOutlet weak var serviceColorView: UIView!
  @IBOutlet weak var serviceShortNameLabel: TKUIStyledLabel!
  @IBOutlet weak var serviceTimeLabel: TKUIStyledLabel!
  @IBOutlet weak var serviceOperatorLabel: TKUIStyledLabel!
  
  @IBOutlet weak var dismissButton: UIButton!
  
  @IBOutlet weak var accessoryStack: UIStackView!
  
  static func newInstance() -> TKUIServiceTitleView {
    return Bundle.tripKitUI.loadNibNamed("TKUIServiceTitleView", owner: self, options: nil)?.first as! TKUIServiceTitleView
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    backgroundColor = .tkBackground

    serviceTitleLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .title2)
    serviceTitleLabel.textColor = .tkLabelPrimary
    serviceTitleLabel.text = nil
    
    serviceShortNameLabel.text = nil
    serviceOperatorLabel.text = nil

    serviceTimeLabel.textColor = .tkLabelSecondary
    serviceTimeLabel.text = nil
    
    dismissButton.setImage(TGCard.closeButtonImage, for: .normal)
    dismissButton.setTitle(nil, for: .normal)
    dismissButton.accessibilityLabel = Loc.Close
  }

}

// MARK: - TKUIDepartureCellContent compatibility

extension TKUIServiceTitleView {
  
  func configure(with model: TKUIDepartureCellContent) {
    serviceTitleLabel.text = model.lineText ?? Loc.Service
    
    serviceImageView.setImage(with: model.imageURL, asTemplate: model.imageIsTemplate, placeholder: model.placeholderImage)
    serviceImageView.tintColor = model.imageTintColor ?? .tkLabelPrimary
    
    serviceShortNameLabel.text = model.serviceShortName
    
    serviceOperatorLabel.text = model.serviceOperatorName
    serviceOperatorLabel.isHidden = model.serviceOperatorName == nil

    if let serviceColor = model.serviceColor {
      serviceShortNameLabel.textColor = serviceColor.isDark ? .tkLabelOnDark : .tkLabelOnLight
      serviceColorView.backgroundColor = serviceColor
    } else {
      serviceShortNameLabel.textColor = .tkBackground
      serviceColorView.backgroundColor = .tkLabelPrimary
    }
    
    serviceTimeLabel.attributedText = model.timeText
    serviceTimeLabel.accessibilityLabel = model.accessibilityTimeText ?? model.timeText.string
  }
  
}
