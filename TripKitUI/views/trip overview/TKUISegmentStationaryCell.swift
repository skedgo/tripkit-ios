//
//  TKUISegmentStationaryCell.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TKUISegmentStationaryCell: UITableViewCell {
  
  @IBOutlet weak var timeLabel: UILabel!
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  
  @IBOutlet weak var lineWrapper: UIView!
  @IBOutlet weak var topLine: UIView!
  @IBOutlet weak var lineDot: UIView!
  @IBOutlet weak var bottomLine: UIView!
  
  static let nib = UINib(nibName: "TKUISegmentStationaryCell", bundle: Bundle(for: TKUISegmentStationaryCell.self))
  
  static let reuseIdentifier = "TKUISegmentStationaryCell"
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }
    
}

extension TKUISegmentStationaryCell {
  
  func configure(with item: TKUITripOverviewViewModel.StationaryItem) {
    if let time = item.time {
      timeLabel.text = TKStyleManager.timeString(time, for: item.timeZone)
      timeLabel.textColor = TKStyleManager.darkTextColor()
    } else {
      timeLabel.text = nil
    }
    
    titleLabel.text = item.title
    titleLabel.textColor = TKStyleManager.darkTextColor()
    subtitleLabel.text = item.subtitle
    subtitleLabel.textColor = TKStyleManager.lightTextColor()
    subtitleLabel.isHidden = item.subtitle == nil

    lineDot.layer.borderColor = UIColor.black.cgColor
    lineDot.layer.borderWidth = 2
    lineDot.layer.cornerRadius = lineDot.frame.width / 2
    topLine.backgroundColor = item.topConnection?.color ?? .lightGray
    bottomLine.backgroundColor = item.bottomConnection?.color ?? .lightGray
  }
  
  func configure(with item: TKUITripOverviewViewModel.TerminalItem) {
    if let time = item.time {
      timeLabel.text = TKStyleManager.timeString(time, for: item.timeZone)
      timeLabel.textColor = TKStyleManager.darkTextColor()
    } else {
      timeLabel.text = nil
    }

    titleLabel.text = item.title
    titleLabel.textColor = TKStyleManager.darkTextColor()
    subtitleLabel.text = item.subtitle
    subtitleLabel.textColor = TKStyleManager.lightTextColor()
    subtitleLabel.isHidden = item.subtitle == nil
    
    lineDot.layer.borderColor = (item.connection?.color ?? .lightGray).cgColor
    lineDot.layer.borderWidth = 2
    lineDot.layer.cornerRadius = lineDot.frame.width / 2
    topLine.backgroundColor = item.connection?.color ?? .lightGray
    topLine.isHidden = item.isStart
    bottomLine.backgroundColor = item.connection?.color ?? .lightGray
    bottomLine.isHidden = !item.isStart
  }
  
}
