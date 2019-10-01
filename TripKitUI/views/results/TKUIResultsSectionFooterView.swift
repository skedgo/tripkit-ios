//
//  TKUIResultsSectionFooterView.swift
//  TripKit
//
//  Created by Adrian Schönig on 15.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TKUIResultsSectionFooterView: UITableViewHeaderFooterView {

  static let nib = UINib(nibName: "TKUIResultsSectionFooterView", bundle: Bundle(for: TKUIResultsSectionFooterView.self))
  static let reuseIdentifier = "TKUIResultsSectionFooterView"
  
  @IBOutlet weak var badgeWrapper: UIView!
  @IBOutlet weak var badgeIcon: UIImageView!
  @IBOutlet weak var badgeLabel: UILabel!
  
  @IBOutlet weak var costLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    contentView.backgroundColor = .tkBackgroundTile
    
    badgeWrapper.isHidden = true
    badgeIcon.tintColor = .tkFilledButtonTextColor
    badgeLabel.text = nil
    badgeLabel.textColor = .tkFilledButtonTextColor
    badgeLabel.font = TKStyleManager.customFont(forTextStyle: .caption1)
    costLabel.text = nil
    costLabel.textColor = .tkLabelSecondary
    costLabel.font = TKStyleManager.customFont(forTextStyle: .caption1)
  }
  
  var badge: (icon: UIImage?, text: String, background: UIColor)? {
    get {
      guard let text = badgeLabel.text else {
        return nil
      }
      return (badgeIcon.image, text, badgeWrapper.backgroundColor ?? .tkBackground)
    }
    set {
      guard let badge = newValue else {
        badgeWrapper.isHidden = true
        return
      }
      badgeWrapper.isHidden = false
      badgeIcon.image = badge.icon
      badgeLabel.text = badge.text.uppercased(with: .current)
      badgeWrapper.backgroundColor = badge.background
    }
  }
  
  var cost: String? {
    get {
      return costLabel.text
    }
    set {
      costLabel.text = newValue
    }
  }
  
  var attributedCost: NSAttributedString? {
    get {
      return costLabel.attributedText
    }
    set {
      costLabel.attributedText = newValue
    }
  }
  
}
