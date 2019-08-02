//
//  TKUIServiceTitleView.swift
//  TripGoAppKit
//
//  Created by Adrian Schönig on 19.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

import TGCardViewController

class TKUIServiceTitleView: UIView {

  @IBOutlet weak var serviceTitleLabel: TKUIStyledLabel!
  
  @IBOutlet weak var serviceImageView: UIImageView!
  @IBOutlet weak var serviceColorView: UIView!
  @IBOutlet weak var serviceShortNameLabel: TKUIStyledLabel!
  
  @IBOutlet weak var serviceTimeLabel: TKUIStyledLabel!
  
  @IBOutlet weak var dismissButton: UIButton!
  
  private let disposeBag = DisposeBag()
  
  static func newInstance() -> TKUIServiceTitleView {
    return Bundle(for: TKUIServiceTitleView.self).loadNibNamed("TKUIServiceTitleView", owner: self, options: nil)?.first as! TKUIServiceTitleView
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()

    serviceTitleLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .title2)
    serviceTitleLabel.textColor = .tkLabelPrimary
    serviceTitleLabel.text = nil
    
    serviceShortNameLabel.text = nil
    
    serviceTimeLabel.textColor = .tkLabelSecondary
    serviceTimeLabel.text = nil
    
    dismissButton.setImage(TGCard.closeButtonImage, for: .normal)
    dismissButton.setTitle(nil, for: .normal)
  }

}

// MARK: - TKUIDepartureCellContent compatibility

extension TKUIServiceTitleView {
  func configure(with model: TKUIDepartureCellContent) {
    
    serviceTitleLabel.text = model.lineText ?? "Service" // TODO: Localise
    
    serviceImageView.setImage(with: model.imageURL, asTemplate: model.imageIsTemplate, placeholder: model.placeHolderImage)
    serviceImageView.tintColor = model.imageTintColor ?? TKStyleManager.darkTextColor()
    
    let serviceColor = model.serviceColor ?? .tkLabelPrimary
    serviceShortNameLabel.text = model.serviceShortName
    serviceShortNameLabel.textColor = serviceColor.isDark() ? .tkBackground : .tkLabelPrimary
    serviceColorView.backgroundColor = serviceColor
    
    serviceTimeLabel.attributedText = model.timeText
  }
}
