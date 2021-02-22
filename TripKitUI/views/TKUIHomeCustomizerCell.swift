//
//  TKUIHomeCustomizerCell.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 18/2/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TKUIHomeCustomizerCell: UITableViewCell {

  @IBOutlet weak var stateImageView: UIImageView!
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  
  static let reuseIdentifier = "TKUIHomeCustomizerCell"
  static let nib = UINib(nibName: "TKUIHomeCustomizerCell", bundle: .tripKitUI)

  override func awakeFromNib() {
    super.awakeFromNib()

    titleLabel.font = TKStyleManager.customFont(forTextStyle: .body)
    titleLabel.textColor = .tkLabelPrimary
    iconImageView.tintColor = .tkAppTintColor
    stateImageView.tintColor = .tkAppTintColor
  }
    
}
