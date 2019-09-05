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
  @IBOutlet weak var linePinImageView: UIImageView!
  
  /// Space from the label stack across the time stack to the superview. Ideally
  /// we wouldn't need this and instead just have a fixed space between the label
  /// stack and the time stack, but Auto Layout can't seem to handle this and
  /// won't allow the label stack to grow vertically. So we have this, and toggle it
  /// between 82 and 16 depending on whether there's a time stack.
  @IBOutlet weak var labelStackTrailingConstraint: NSLayoutConstraint!
  
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

    if !item.timesAreFixed {
      timeStack.isHidden = true

    } else if let start = startText, let end = endText, start != end {
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
    labelStackTrailingConstraint.constant = timeStack.isHidden ? 16 : 82

    titleLabel.text = item.title
    subtitleLabel.text = item.subtitle
    subtitleLabel.isHidden = item.subtitle == nil

    linePinImageView.isHidden = true
    lineDot.isHidden = false
    lineDot.layer.borderColor = (item.bottomConnection?.color ?? item.topConnection?.color ?? .tkLabelPrimary).cgColor
    lineDot.layer.borderWidth = 3
    lineDot.layer.cornerRadius = lineDot.frame.width / 2
    topLine.backgroundColor = item.topConnection?.color
    topLine.isHidden = item.topConnection?.color == nil
    bottomLine.backgroundColor = item.bottomConnection?.color
    bottomLine.isHidden = item.bottomConnection?.color == nil
  }
  
  func configure(with item: TKUITripOverviewViewModel.TerminalItem) {
    timeEndLabel.isHidden = true

    if item.timesAreFixed, let time = item.time {
      timeStack.isHidden = false
      timeLabel.text = TKStyleManager.timeString(time, for: item.timeZone)
    } else {
      timeStack.isHidden = true
    }
    labelStackTrailingConstraint.constant = timeStack.isHidden ? 16 : 82

    titleLabel.text = item.title
    subtitleLabel.text = item.subtitle
    subtitleLabel.isHidden = item.subtitle == nil
    
    linePinImageView.isHidden = false
    linePinImageView.tintColor = item.connection?.color ?? .tkLabelPrimary
    linePinImageView.backgroundColor = .tkBackground
    lineDot.isHidden = true

    topLine.backgroundColor = item.connection?.color
    topLine.isHidden = item.isStart || item.connection?.color == nil
    bottomLine.backgroundColor = item.connection?.color
    bottomLine.isHidden = !item.isStart || item.connection?.color == nil
  }
  
}
