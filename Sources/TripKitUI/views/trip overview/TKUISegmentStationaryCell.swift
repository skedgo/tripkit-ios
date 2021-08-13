//
//  TKUISegmentStationaryCell.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

import TripKit

#if SWIFT_PACKAGE
import TripKitObjc
#endif

class TKUISegmentStationaryCell: UITableViewCell {
  
  @IBOutlet weak var timeStack: UIStackView!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var timeEndLabel: UILabel!
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var buttonStackView: UIStackView!

  @IBOutlet weak var lineWrapper: UIView!
  @IBOutlet weak var topLine: UIView!
  @IBOutlet weak var lineDot: UIView!
  @IBOutlet weak var bottomLine: UIView!
  @IBOutlet weak var linePinImageView: UIImageView!
  
  @IBOutlet weak var lineDotWidthConstraint: NSLayoutConstraint!
  
  /// Space from the label stack across the time stack to the superview. Ideally
  /// we wouldn't need this and instead just have a fixed space between the label
  /// stack and the time stack, but Auto Layout can't seem to handle this and
  /// won't allow the label stack to grow vertically. So we have this, and toggle it
  /// between 82 and 16 depending on whether there's a time stack.
  @IBOutlet weak var labelStackTrailingConstraint: NSLayoutConstraint!
  
  static let nib = UINib(nibName: "TKUISegmentStationaryCell", bundle: Bundle(for: TKUISegmentStationaryCell.self))
  
  static let reuseIdentifier = "TKUISegmentStationaryCell"
  
  private var disposeBag = DisposeBag()

  override func awakeFromNib() {
    super.awakeFromNib()
    
    backgroundColor = .clear
    lineDot.backgroundColor = .tkBackground
    
    titleLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .body)
    titleLabel.textColor = .tkLabelPrimary
    subtitleLabel.textColor = .tkLabelSecondary
    
    timeLabel.textColor = .tkLabelPrimary
    timeLabel.numberOfLines = 0
    timeEndLabel.textColor = .tkLabelPrimary
    timeEndLabel.numberOfLines = 0
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    
    disposeBag = DisposeBag()
  }
  
  override func tintColorDidChange() {
    super.tintColorDidChange()
    
    buttonStackView.arrangedSubviews
      .compactMap { $0 as? UIButton }
      .forEach { $0.setTitleColor(tintColor, for: .normal) }
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

extension TKUITripOverviewViewModel.TimeInfo {
  var delay: (mins: String?, color: UIColor)? {
    guard let timetable = timetableTime else { return nil }
    let color: UIColor
    
    let delay = actualTime.timeIntervalSince(timetable)
    switch delay {
    case ...(-60):
      color = .tkStateWarning
    case ...120:
      color = .tkStateSuccess
    default:
      color = .tkStateError
    }
    
    let rounded = Int(round(abs(delay) / 60.0))
    let mins: String?
    if delay < -60 {
      mins = "-\(rounded)"
    } else if delay > 60 {
      mins = "+\(rounded)"
    } else {
      mins = nil
    }
    return (mins, color)
  }
  
  func timeString(for timeZone: TimeZone?) -> (NSAttributedString, String) {
    timeStringWithStrike(for: timeZone)
  }
  
  func timeStringWithStrike(for timeZone: TimeZone?) -> (NSAttributedString, String) {
    let actual = TKStyleManager.timeString(actualTime, for: timeZone)
    if let timetableTime = timetableTime, let delay = self.delay {
      let attributed = NSMutableAttributedString(string: actual, attributes: [
        .foregroundColor: delay.color,
        .font: TKStyleManager.boldCustomFont(forTextStyle: .footnote)
      ])
      
      let timetable = TKStyleManager.timeString(timetableTime, for: timeZone)
      if timetable != actual {
        attributed.append(NSAttributedString(string: "\n"))
        attributed.append(NSAttributedString(string: timetable, attributes: [
          .foregroundColor: TKColor.tkLabelSecondary,
          .font: TKStyleManager.customFont(forTextStyle: .footnote),
          .strikethroughStyle: NSNumber(1)
        ]))
      }
      return (attributed, actual)
    }
    
    if let delay = self.delay {
      var combined = actual
      if let mins = delay.mins {
        combined += "\n" + mins
      }
      return (
        NSAttributedString(
          string: combined,
          attributes: [
            .foregroundColor: delay.color,
            .font: TKStyleManager.boldCustomFont(forTextStyle: .footnote)
          ]
        ), actual
      )

    } else {
      return (
        NSAttributedString(
          string: actual,
          attributes: [
            .foregroundColor: UIColor.tkLabelPrimary
          ]
        ), actual
      )
    }
  }
  
  func timeStringWithPlus(for timeZone: TimeZone?) -> (NSAttributedString, String) {
    let actual = TKStyleManager.timeString(actualTime, for: timeZone)
    if let delay = self.delay {
      var combined = actual
      if let mins = delay.mins {
        combined += "\n" + mins
      }
      return (
        NSAttributedString(
          string: combined,
          attributes: [
            .foregroundColor: delay.color,
            .font: TKStyleManager.boldCustomFont(forTextStyle: .footnote)
          ]
        ), actual
      )

    } else {
      return (
        NSAttributedString(
          string: actual,
          attributes: [
            .foregroundColor: UIColor.tkLabelPrimary
          ]
        ), actual
      )
    }
  }
}

extension TKUISegmentStationaryCell {
  
  func configure(with item: TKUITripOverviewViewModel.StationaryItem, for card: TKUITripOverviewCard) {
    let startText = item.startTime?.timeString(for: item.timeZone)
    let endText = item.endTime?.timeString(for: item.timeZone)

    if !item.timesAreFixed {
      timeStack.isHidden = true

    } else if let start = startText, let end = endText, start.1 != end.1 {
      timeStack.isHidden = false
      timeEndLabel.isHidden = false
      timeLabel.attributedText = start.0
      timeLabel.accessibilityLabel = Loc.Arrives(atTime: start.1)
      timeEndLabel.attributedText = end.0
      timeEndLabel.accessibilityLabel = Loc.Departs(atTime: end.1)

    } else if let time = startText ?? endText {
      timeStack.isHidden = false
      timeEndLabel.isHidden = true
      timeLabel.attributedText = time.0
      timeLabel.accessibilityLabel = Loc.At(time: time.1)
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

    let width: CGFloat = item.isContinuation ? 12 : 18
    lineDotWidthConstraint.constant = width
    lineDot.layer.cornerRadius = width / 2

    topLine.backgroundColor = item.topConnection?.color
    topLine.isHidden = item.topConnection?.color == nil
    bottomLine.backgroundColor = item.bottomConnection?.color
    bottomLine.isHidden = item.bottomConnection?.color == nil

    let buttons = item.actions.map { TKUISegmentCellHelper.buildView(for: $0, model: item.segment, for: card, tintColor: tintColor, disposeBag: disposeBag) }
    buttonStackView.resetViews(buttons)
  }
  
  func configure(with item: TKUITripOverviewViewModel.TerminalItem, for card: TKUITripOverviewCard) {
    timeEndLabel.isHidden = true

    if item.timesAreFixed, let text = item.time?.timeString(for: item.timeZone) {
      timeStack.isHidden = false
      timeLabel.attributedText = text.0
      timeLabel.accessibilityLabel = text.1
    } else {
      timeStack.isHidden = true
    }
    labelStackTrailingConstraint.constant = timeStack.isHidden ? 16 : 82

    titleLabel.text = item.title
    subtitleLabel.text = item.subtitle
    subtitleLabel.isHidden = item.subtitle == nil
    
    if let color = item.connection?.color {
      // If there's a line, don't use the pin as that looks a bit funny, just
      // use the circle instead.
      linePinImageView.isHidden = true
      lineDot.isHidden = false
      lineDot.layer.borderColor = color.cgColor
      lineDot.layer.borderWidth = 3
      lineDot.layer.cornerRadius = lineDot.frame.width / 2
      lineDotWidthConstraint.constant = 18

    } else {
      linePinImageView.isHidden = false
      linePinImageView.tintColor = item.connection?.color ?? .tkLabelPrimary
      linePinImageView.backgroundColor = .clear
      lineDot.isHidden = true
    }
    

    topLine.backgroundColor = item.connection?.color
    topLine.isHidden = item.isStart || item.connection?.color == nil
    bottomLine.backgroundColor = item.connection?.color
    bottomLine.isHidden = !item.isStart || item.connection?.color == nil
    
    let buttons = item.actions.map { TKUISegmentCellHelper.buildView(for: $0, model: item.segment, for: card, tintColor: tintColor, disposeBag: disposeBag) }
    buttonStackView.resetViews(buttons)
  }
  
}
