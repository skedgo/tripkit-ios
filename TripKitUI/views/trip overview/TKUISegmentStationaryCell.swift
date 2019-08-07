//
//  TKUISegmentStationaryCell.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TKUISegmentStationaryCell: UITableViewCell {
  
  @IBOutlet weak var timeStack: UIStackView!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var timeEndLabel: UILabel!
  
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
    
    titleLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .body)
    titleLabel.textColor = .tkLabelPrimary
    subtitleLabel.textColor = .tkLabelSecondary
    
    timeLabel.textColor = .tkLabelPrimary
    timeEndLabel.textColor = .tkLabelPrimary
  }

  override func setHighlighted(_ highlighted: Bool, animated: Bool) {
    // Not calling super to not override line colors
    UIView.animate(withDuration: animated ? 0.25 : 0) {
      self.contentView.backgroundColor = highlighted ? TKStyleManager.cellSelectionBackgroundColor() : .white
    }
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    setHighlighted(selected, animated: animated);
  }
  
}

extension TKUISegmentStationaryCell {
  
  func configure(with item: TKUITripOverviewViewModel.StationaryItem) {
    let startText = item.startTime.map { TKStyleManager.timeString($0, for: item.timeZone) }
    let endText = item.endTime.map { TKStyleManager.timeString($0, for: item.timeZone) }

    if let start = startText, let end = endText, start != end {
      timeStack.isHidden = false
      timeEndLabel.isHidden = false
      timeLabel.text = start
      timeEndLabel.text = end

    } else if let time = startText ?? endText {
      timeStack.isHidden = false
      timeEndLabel.isHidden = true
      timeLabel.text = time
      timeEndLabel.text = nil
    
    } else {
      timeStack.isHidden = true
    }
    
    titleLabel.text = item.title
    
    subtitleLabel.text = item.subtitle
    subtitleLabel.isHidden = item.subtitle == nil

    lineDot.layer.borderColor = UIColor.black.cgColor
    lineDot.layer.borderWidth = 2
    lineDot.layer.cornerRadius = lineDot.frame.width / 2
    topLine.backgroundColor = item.topConnection?.color ?? .lightGray
    bottomLine.backgroundColor = item.bottomConnection?.color ?? .lightGray
  }
  
  func configure(with item: TKUITripOverviewViewModel.TerminalItem) {
    timeEndLabel.isHidden = true
    if let time = item.time {
      timeStack.isHidden = false
      timeLabel.text = TKStyleManager.timeString(time, for: item.timeZone)
    } else {
      timeStack.isHidden = true
    }

    titleLabel.text = item.title
    subtitleLabel.text = item.subtitle
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
