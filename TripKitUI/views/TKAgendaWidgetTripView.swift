//
//  TKWidgetTripView.swift
//  TripGo
//
//  Created by Kuan Lun Huang on 11/09/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import SGCoreUIKit

public class TKAgendaWidgetTripView: UIView {

  @IBOutlet weak var tripSegmentView: SGTripSegmentsView!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var destinationTitle: UILabel!
  @IBOutlet weak var destinationTimes: UILabel!
  @IBOutlet weak var timeToLeaveUnitLabel: UILabel!
  @IBOutlet weak var timeToLeaveNumberLabel: UILabel!
  
  public static func makeView() -> TKAgendaWidgetTripView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("TKAgendaWidgetTripView", owner: self, options: nil)?.first as! TKAgendaWidgetTripView
  }
  
  public func configure(for trip: STKTrip, to destination: SGTrackItem) {
    let segments = trip.segments(with: .inSummary)
    tripSegmentView.configure(forSegments: segments, allowSubtitles: true, allowInfoIcons: false)
    
    imageView.image = destination.trackIcon!()
    destinationTitle.text = destination.title()
    
    if let start = destination.startDate() {
      destinationTimes.isHidden = false
      
      let duration = destination.duration()
      if duration == -1 {
        let prefix = NSLocalizedString("Arrive at ", comment: "")
        destinationTimes.text = prefix + SGStyleManager.timeString(start, for: nil)
      } else {
        let end = start.addingTimeInterval(duration)
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        destinationTimes.text = formatter.string(from: start, to: end)
      }
    } else {
      destinationTimes.text = nil
      destinationTimes.isHidden = true
    }
    
    let timeToDeparture = trip.departureTime.timeIntervalSinceNow
    let timeToLeave = readableTimeToLeave(from: timeToDeparture)
    timeToLeaveNumberLabel.text = timeToLeave.number
    timeToLeaveUnitLabel.text = timeToLeave.unit
  }
  
  // MARK: -
  
  override public func awakeFromNib() {
    super.awakeFromNib()
    
    imageView.backgroundColor = SGStyleManager.globalTintColor()
    imageView.tintColor = UIColor.white
    imageView.layer.cornerRadius = 20
    imageView.layer.masksToBounds = true
    imageView.contentMode = .center
  }
  
  // MARK: - Utilities
  
  private func readableTimeToLeave(from interval: TimeInterval) -> (number: String, unit: String) {
    let mins = interval / 60
    let isFuture = mins >= 0
    let absoluteMins = mins * (isFuture ? 1 : -1)
    
    var durationString: String
    
    if absoluteMins < 60 {
      // e.g., 35m
      let rounded = Int(floor(absoluteMins))
      durationString = SGKObjcDateHelper.durationString(forMinutes: rounded)
      
    } else if absoluteMins < 1440 {
      // e.g., 1h
      let hours = Int(absoluteMins/60)
      durationString = SGKObjcDateHelper.durationString(forHours: hours)
      
    } else {
      // e.g., 1d
      let days = Int(absoluteMins/1440)
      durationString = SGKObjcDateHelper.durationString(forDays: days)
    }
    
    // extract the decimal parts, e.g., start with 35m
    let timeToLeaveNumber = durationString.characters // => ["3", "5", "m"]
      .flatMap { character -> String? in
        if let _ = Int(String(character)) {
          return String(character)
        } else {
          return nil
        }
      } // => ["3", "5"]
      .reduce(isFuture ? "" : "-") { $0 + $1 } // "35"
    
    // extract the unit part, e.g., start with 35m
    let timeToLeaveUnit = durationString
      .components(separatedBy: CharacterSet.decimalDigits) // => ["", "", "m"]
      .filter { !$0.isEmpty } // => ["m"]
      .reduce("") { $0 + $1 } // => "m"
    
    return (timeToLeaveNumber, timeToLeaveUnit) // => ("35", "m")
  }
}

