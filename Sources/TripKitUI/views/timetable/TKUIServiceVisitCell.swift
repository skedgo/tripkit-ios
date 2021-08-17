//
//  TKUIServiceVisitCell.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 19.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

class TKUIServiceVisitCell: UITableViewCell {

  @IBOutlet weak var timeStack: UIStackView!
  @IBOutlet weak var arrivalTimeLabel: UILabel!
  @IBOutlet weak var departureTimeLabel: UILabel!
  
  @IBOutlet weak var stopWrapperStack: UIStackView!
  @IBOutlet weak var stopNameStack: UIStackView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var setReminderButton: UIButton!
  
  @IBOutlet weak var accessibilityWrapper: UIView!
  @IBOutlet weak var accessibilityImageView: UIImageView!
  @IBOutlet weak var accessibilityTitleLabel: UILabel!
  
  @IBOutlet weak var topLine: UIView!
  @IBOutlet weak var bottomLine: UIView!
  @IBOutlet weak var outerDot: UIView!
  @IBOutlet weak var innerDot: UIView!
  
  static let nib = UINib(nibName: "TKUIServiceVisitCell", bundle: Bundle(for: TKUIServiceVisitCell.self))
  
  static let reuseIdentifier = "TKUIServiceVisitCell"
  
  var isFirstStop: Bool = false {
    didSet {
      topLine.isHidden = isFirstStop
    }
  }
  
  var isLastStop: Bool = false {
    didSet {
      bottomLine.isHidden = isLastStop
    }
  }
  
  var enableReminder = false {
    didSet {
      setReminderButton.isHidden = !enableReminder
      stopWrapperStack.spacing = enableReminder ? 8 : 0
    }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    backgroundColor = .tkBackground

    outerDot.layer.cornerRadius = outerDot.frame.width / 2
    innerDot.layer.cornerRadius = innerDot.frame.width / 2
  }
  
  override func setHighlighted(_ highlighted: Bool, animated: Bool) {
    // Not calling super to not override line colors
    UIView.animate(withDuration: animated ? 0.25 : 0) {
      self.contentView.backgroundColor = highlighted ? .tkBackgroundSelected : .tkBackground
    }
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    setHighlighted(selected, animated: animated);
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    topLine.isHidden = false
    bottomLine.isHidden = false
    arrivalTimeLabel.isHidden = false
    departureTimeLabel.isHidden = false
  }
    
}

extension TKUIServiceVisitCell {
  func setTiming(_ timing: TKServiceTiming, timeZone: TimeZone, isVisited: Bool, realTime: StopVisits.RealTime) {
    
    let textColor: UIColor = isVisited ? realTime.color : .tkLabelTertiary

    arrivalTimeLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .footnote)
    arrivalTimeLabel.textColor = textColor
    departureTimeLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .footnote)
    departureTimeLabel.textColor = textColor

    var arrivalText: String?
    var departureText: String?
    
    switch timing {
    case .timetabled(let arrival, let departure):

      if let arrival = arrival {
        arrivalText = TKStyleManager.timeString(arrival, for: timeZone)
      }
      if let departure = departure {
        departureText = TKStyleManager.timeString(departure, for: timeZone)
      }
      
    case .frequencyBased:
      // TODO: Would be good to show travel time here
      arrivalText = nil
      departureText = nil
    }
    
    if arrivalText == departureText {
      arrivalText = nil
    }

    if let arrival = arrivalText {
      // Be more verbose when showing both times
      arrivalTimeLabel.accessibilityLabel = Loc.Arrives(atTime:arrival)
      departureTimeLabel.accessibilityLabel = departureText.map { Loc.Departs(atTime:$0) }
    } else {
      // Otherwise just speak the single time
      arrivalTimeLabel.accessibilityLabel = nil
      departureTimeLabel.accessibilityLabel = departureText
    }
    
    arrivalTimeLabel.text = arrivalText
    departureTimeLabel.text = departureText
    arrivalTimeLabel.isHidden = arrivalText == nil
    timeStack.spacing = (departureText != nil && arrivalText != nil) ? 4: 0
  }
  
  func setTitle(_ title: String?, subtitle: String? = nil,  isVisited: Bool) {
    
    titleLabel.text = title
    titleLabel.font = TKStyleManager.customFont(forTextStyle: .body)
    titleLabel.textColor = isVisited ? .tkLabelPrimary : .tkLabelTertiary
    
    subtitleLabel.text = subtitle
    subtitleLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
    subtitleLabel.textColor = isVisited ? .tkLabelSecondary : .tkLabelTertiary
    
    accessibilityTitleLabel.textColor = isVisited ? .tkLabelSecondary : .tkLabelTertiary
    accessibilityImageView.alpha = isVisited ? 1 : 0.3
    
    stopNameStack.spacing = (subtitle != nil) ? 4 : 0
  }
  
  func setStopAccessibility(_ accessibility: TKWheelchairAccessibility) {
    guard accessibility.showInUI() else {
      accessibilityWrapper.isHidden = true
      return
    }

    accessibilityWrapper.isHidden = false
    accessibilityImageView.image = accessibility.icon

    // Not setting a title, unless inaccessible as it's very
    // verbose otherwise
    if accessibility == .notAccessible {
      accessibilityTitleLabel.text = accessibility.title
      accessibilityWrapper.accessibilityLabel = nil
    } else {
      accessibilityTitleLabel.text = nil
      accessibilityWrapper.accessibilityLabel = accessibility.title
    }
    
    stopNameStack.spacing = 4
  }
}

extension TKUIServiceVisitCell {
  
  func configure(with item: TKUIServiceViewModel.Item) {
    setTiming(item.timing, timeZone: item.timeZone, isVisited: item.isVisited, realTime: item.realTimeStatus)

    setTitle(item.title, isVisited: item.isVisited)
    
    // NOTE: This is the accessibility of the stop-only, as the
    // service accessibility is assumed covered by the title
    // of the screen.
    setStopAccessibility(item.dataModel.stop.wheelchairAccessibility)
    
    topLine.backgroundColor = item.topConnection
    topLine.isHidden = item.topConnection == nil
    bottomLine.backgroundColor = item.bottomConnection
    bottomLine.isHidden = item.bottomConnection == nil
    
    var dotColor = item.topConnection ?? item.bottomConnection
    if item.isVisited {
      dotColor = dotColor?.withAlphaComponent(1)
    } else {
    }
    outerDot.backgroundColor = dotColor
  }
  
  func configure(with visit: StopVisits, embarkOn embarkation: StopVisits, disembarkOn disembarkation: StopVisits?) {
    
    var isVisited: Bool
    if visit < embarkation {
      isVisited = false
    } else if let disembarkation = disembarkation, visit > disembarkation {
      isVisited = false
    } else {
      isVisited = true
    }
    
    setTiming(visit.timing, timeZone: visit.timeZone, isVisited: isVisited, realTime: visit.realTimeStatus)
    
    let title = visit.stop.title ?? visit.stop.location?.title
    setTitle(title, isVisited: isVisited)
    
    let serviceColor = visit.service.color ?? .black
    outerDot.backgroundColor = serviceColor
    topLine.backgroundColor = (isVisited && visit != embarkation) ? serviceColor : serviceColor.withAlphaComponent(0.3)
    bottomLine.backgroundColor = (isVisited && visit != disembarkation) ? serviceColor : serviceColor.withAlphaComponent(0.3)
    topLine.isHidden = false
    bottomLine.isHidden = false
    
    // NOTE: This is the accessibility of the stop-only, as the
    // service accessibility is assumed covered by the title
    // of the screen.
    setStopAccessibility(visit.stop.wheelchairAccessibility)
  }
  
}
