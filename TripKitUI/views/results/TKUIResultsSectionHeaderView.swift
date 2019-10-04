//
//  TKUIResultsSectionHeaderView.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 04.10.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TKUIResultsSectionHeaderView: UITableViewHeaderFooterView {

  static let nib = UINib(nibName: "TKUIResultsSectionHeaderView", bundle: Bundle(for: TKUIResultsSectionHeaderView.self))
  static let reuseIdentifier = "TKUIResultsSectionHeaderView"
  
  static func newInstance() -> TKUIResultsSectionHeaderView {
    return Bundle.tripKitUI.loadNibNamed("TKUIResultsSectionHeaderView", owner: self, options: nil)?.first as! TKUIResultsSectionHeaderView
  }
  
  @IBOutlet weak var wrapper: UIView!
  @IBOutlet weak var badgeIcon: UIImageView!
  @IBOutlet weak var badgeLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    wrapper.backgroundColor = .tkBackgroundTile
    
    badgeIcon.image = nil
    badgeIcon.tintColor = .tkFilledButtonTextColor
    badgeLabel.text = nil
    badgeLabel.textColor = .tkFilledButtonTextColor
    badgeLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .subheadline)
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()

    badgeIcon.image = nil
    badgeLabel.text = nil
  }
  
  var badge: (icon: UIImage?, text: String, color: UIColor) {
    get {
      (badgeIcon.image, badgeLabel.text ?? "", badgeLabel.textColor ?? .tkLabelPrimary)
    }
    set {
      badgeIcon.image = newValue.icon
      badgeIcon.tintColor = newValue.color
      badgeLabel.text = newValue.text
      badgeLabel.textColor = newValue.color
    }
  }
  
}
