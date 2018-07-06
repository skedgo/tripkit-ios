//
//  TKUISegmentMovingCell.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TKUISegmentMovingCell: UITableViewCell {
  @IBOutlet weak var modeImage: UIImageView!
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  
  @IBOutlet weak var lineWrapper: UIView!
  @IBOutlet weak var line: UIView!
  
  static let nib = UINib(nibName: "TKUISegmentMovingCell", bundle: Bundle(for: TKUISegmentMovingCell.self))
  
  static let reuseIdentifier = "TKUISegmentMovingCell"
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }
    
}

extension TKUISegmentMovingCell {
  
  func configure(with item: TKUITripOverviewViewModel.MovingItem) {
    modeImage.setImage(with: item.iconURL, asTemplate: item.iconIsTemplate, placeholder: item.icon)
    modeImage.tintColor = SGStyleManager.darkTextColor() // TODO: add a colorCodingTransitIcon here, too?
    
    titleLabel.text = item.title
    titleLabel.textColor = SGStyleManager.darkTextColor()
    subtitleLabel.text = item.notes
    subtitleLabel.textColor = SGStyleManager.lightTextColor()
    subtitleLabel.isHidden = item.notes == nil

    line.backgroundColor = item.connection?.color ?? .lightGray
  }
  
}
