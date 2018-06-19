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
    
    badgeWrapper.isHidden = true
    badgeIcon.tintColor = .white
    badgeLabel.text = nil
    costLabel.text = nil
  }
  
  var badge: (icon: UIImage, text: String, background: UIColor)? {
    get {
      guard let icon = badgeIcon.image, let text = badgeLabel.text else {
        return nil
      }
      return (icon, text, badgeWrapper.backgroundColor ?? .white)
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
