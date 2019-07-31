//
//  TKUIServiceVisitCell.swift
//  TripGoAppKit
//
//  Created by Adrian Schönig on 19.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

@objc
public class TKUIServiceVisitCell: UITableViewCell {

  @IBOutlet weak var timeStack: UIStackView!
  @IBOutlet weak var arrivalTimeLabel: UILabel!
  @IBOutlet weak var departureTimeLabel: UILabel!
  
  @IBOutlet weak var stopWrapperStack: UIStackView!
  @IBOutlet weak var stopNameStack: UIStackView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var setReminderButton: UIButton!
  
  @IBOutlet weak var topLine: UIView!
  @IBOutlet weak var bottomLine: UIView!
  @IBOutlet weak var outerDot: UIView!
  @IBOutlet weak var innerDot: UIView!

  @IBOutlet weak var accessoryImageView: UIImageView!
  
  @objc
  public static let nib = UINib(nibName: "TKUIServiceVisitCell", bundle: Bundle(for: TKUIServiceVisitCell.self))
  
  @objc
  public static let reuseIdentifier = "TKUIServiceVisitCell"
  
  @objc
  public var isFirstStop: Bool = false {
    didSet {
      topLine.isHidden = isFirstStop
    }
  }
  
  @objc
  public var isLastStop: Bool = false {
    didSet {
      bottomLine.isHidden = isLastStop
    }
  }
  
  public var enableReminder = false {
    didSet {
      setReminderButton.isHidden = !enableReminder
      stopWrapperStack.spacing = enableReminder ? 8 : 0
    }
  }
  
  override public func awakeFromNib() {
    super.awakeFromNib()
    outerDot.layer.cornerRadius = outerDot.frame.width / 2

    innerDot.layer.cornerRadius = innerDot.frame.width / 2
  }
  
  override public func setHighlighted(_ highlighted: Bool, animated: Bool) {
    // Not calling super to not override line colors
    UIView.animate(withDuration: animated ? 0.25 : 0) {
      self.contentView.backgroundColor = highlighted ? TKStyleManager.cellSelectionBackgroundColor() : .white
    }
  }
  
  override public func setSelected(_ selected: Bool, animated: Bool) {
    setHighlighted(selected, animated: animated);
  }
  
  public override func prepareForReuse() {
    super.prepareForReuse()
    topLine.isHidden = false
    bottomLine.isHidden = false
    arrivalTimeLabel.isHidden = false
    departureTimeLabel.isHidden = false
  }
    
}

extension TKUIServiceVisitCell {
  func setTiming(_ timing: TKServiceTiming, timeZone: TimeZone, isVisited: Bool) {
    let textColor: UIColor = isVisited ? .tkLabelSecondary : .tkLabelTertiary

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
    
    stopNameStack.spacing = (subtitle != nil) ? 4 : 0
  }
  
  func setStopAccessibility(isAccessible: Bool?) {
    guard TKUserProfileHelper.showWheelchairInformation else {
      accessoryImageView.isHidden = true
      return
    }
    
    accessoryImageView.isHidden = false
    switch isAccessible {
    case true?:
      accessoryImageView.image = TripKitUIBundle.imageNamed("icon-wheelchair-accessible")
    case false?:
      accessoryImageView.image = TripKitUIBundle.imageNamed("icon-wheelchair-not-accessible")
    case nil:
      accessoryImageView.image = TripKitUIBundle.imageNamed("icon-wheelchair-unknown")
    }
  }
}

extension TKUIServiceVisitCell {
  
  func configure(with item: TKUIServiceViewModel.Item) {
    setTiming(item.timing, timeZone: item.timeZone, isVisited: item.isVisited)

    setTitle(item.title, isVisited: item.isVisited)
    
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
  
  @objc
  public func configure(with visit: StopVisits, embarkOn embarkation: StopVisits, disembarkOn disembarkation: StopVisits?) {
    
    var isVisited: Bool
    let isBefore = visit.compare(embarkation) == .orderedAscending
    if isBefore {
      isVisited = false
    } else if let disembarkation = disembarkation, visit.compare(disembarkation) == .orderedDescending {
      isVisited = false
    } else {
      isVisited = true
    }
    
    setTiming(visit.timing, timeZone: visit.timeZone, isVisited: isVisited)
    
    let title = visit.stop.title ?? visit.stop.location?.title
    setTitle(title, isVisited: isVisited)
    
    let serviceColor = (visit.service.color as? UIColor) ?? .black
    outerDot.backgroundColor = serviceColor
    topLine.backgroundColor = (isVisited && visit != embarkation) ? serviceColor : serviceColor.withAlphaComponent(0.3)
    bottomLine.backgroundColor = (isVisited && visit != disembarkation) ? serviceColor : serviceColor.withAlphaComponent(0.3)
    topLine.isHidden = false
    bottomLine.isHidden = false
    
    setStopAccessibility(isAccessible: visit.stop.isWheelchairAccessible)
  }
  
}
