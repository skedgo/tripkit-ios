//
//  TKUISegmentStationaryDoubleCell.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 04.01.21.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

import TripKit

class TKUISegmentStationaryDoubleCell: UITableViewCell {
  
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var timeEndLabel: UILabel!
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var endSubtitleLabel: UILabel!

  @IBOutlet weak var lineWrapper: UIView!
  @IBOutlet weak var topLine: UIView!
  @IBOutlet weak var topLineDot: UIView!
  @IBOutlet weak var bottomLine: UIView!
  @IBOutlet weak var bottomLineDot: UIView!
  
  @IBOutlet weak var lineDotWidthConstraint: NSLayoutConstraint!
  
  /// Space from the label stack across the time stack to the superview. Ideally
  /// we wouldn't need this and instead just have a fixed space between the label
  /// stack and the time stack, but Auto Layout can't seem to handle this and
  /// won't allow the label stack to grow vertically. So we have this, and toggle it
  /// between 82 and 16 depending on whether there's a time stack.
  @IBOutlet weak var labelStackTrailingConstraint: NSLayoutConstraint!
  
  static let nib = UINib(nibName: "TKUISegmentStationaryDoubleCell", bundle: .tripKitUI)
  
  static let reuseIdentifier = "TKUISegmentStationaryDoubleCell"
  
  private var disposeBag = DisposeBag()

  override func awakeFromNib() {
    super.awakeFromNib()
    
    backgroundColor = .clear
    topLineDot.backgroundColor = .tkBackgroundNotClear
    bottomLineDot.backgroundColor = .tkBackgroundNotClear
    
    titleLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .body)
    titleLabel.textColor = .tkLabelPrimary
    subtitleLabel.textColor = .tkLabelPrimary
    endSubtitleLabel.textColor = .tkLabelPrimary
    
    timeLabel.textColor = .tkLabelPrimary
    timeLabel.numberOfLines = 0
    timeEndLabel.textColor = .tkLabelPrimary
    timeEndLabel.numberOfLines = 0
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    
    disposeBag = DisposeBag()
  }
  
  override func setHighlighted(_ highlighted: Bool, animated: Bool) {
    // Not calling super to not override line colors
    UIView.animate(withDuration: animated ? 0.25 : 0) {
      self.contentView.backgroundColor = highlighted ? .tkBackgroundSelected : self.backgroundColor
    }
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    setHighlighted(selected, animated: animated);
  }
  
}

extension TKUISegmentStationaryDoubleCell {
  
  func configure(with item: TKUITripOverviewViewModel.StationaryItem) {
    let startText = item.startTime?.timeString(for: item.timeZone)
    let endText = item.endTime?.timeString(for: item.timeZone)

    if !item.timesAreFixed {
      timeLabel.text = nil
      timeEndLabel.text = nil

    } else if let start = startText, let end = endText {
      timeLabel.attributedText = start.0
      timeLabel.accessibilityLabel = Loc.Arrives(atTime: start.1)
      timeEndLabel.attributedText = end.0
      timeEndLabel.accessibilityLabel = Loc.Departs(atTime: end.1)

    } else if let time = startText ?? endText {
      timeLabel.attributedText = time.0
      timeLabel.accessibilityLabel = Loc.At(time: time.1)
      timeEndLabel.text = nil
    
    } else {
      timeLabel.text = nil
      timeEndLabel.text = nil
    }

    titleLabel.text = item.title
    subtitleLabel.text = item.subtitle
    subtitleLabel.isHidden = item.subtitle == nil
    endSubtitleLabel.text = item.endSubtitle
    endSubtitleLabel.isHidden = item.endSubtitle == nil

    topLineDot.layer.borderColor = (item.topConnection?.color ?? .tkLabelPrimary).cgColor
    topLineDot.layer.borderWidth = 3
    bottomLineDot.layer.borderColor = (item.bottomConnection?.color ?? .tkLabelPrimary).cgColor
    bottomLineDot.layer.borderWidth = 3

    let width: CGFloat = 15
    lineDotWidthConstraint.constant = width
    topLineDot.layer.cornerRadius = width / 2
    bottomLineDot.layer.cornerRadius = width / 2

    topLine.backgroundColor = item.topConnection?.color
    topLine.isHidden = item.topConnection?.color == nil
    bottomLine.backgroundColor = item.bottomConnection?.color
    bottomLine.isHidden = item.bottomConnection?.color == nil
  }
  
}
