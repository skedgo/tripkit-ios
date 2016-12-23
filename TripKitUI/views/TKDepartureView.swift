//
//  TKDepartureView.swift
//  TripGo
//
//  Created by Kuan Lun Huang on 11/09/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import SGCoreUIKit

public class TKDepartureView: UIView {

  @IBOutlet weak var tripSegmentView: SGTripSegmentsView!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var destinationTitle: UILabel!
  @IBOutlet weak var destinationTimes: UILabel!
  @IBOutlet weak var timeTitleLabel: UILabel!
  @IBOutlet weak var timeUnitLabel: UILabel!
  @IBOutlet weak var timeNumberLabel: UILabel!
  
  public static func makeView() -> TKDepartureView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("TKDepartureView", owner: self, options: nil)?.first as! TKDepartureView
  }
  
  public func configure(for trip: STKTrip, to destination: SGTrackItemDisplayable) {
    let segments = trip.segments(with: .inSummary)
    tripSegmentView.configure(forSegments: segments, allowSubtitles: true, allowInfoIcons: true)
    
    imageView.image = destination.trackIcon
    destinationTitle.text = destination.title
    
    if let start = destination.startDate {
      destinationTimes.isHidden = false
      
      let duration = destination.duration
      if duration == -1 {
        destinationTimes.text = Loc.ArriveAt(date: SGStyleManager.timeString(start, for: nil))
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
    
    let time = readableTime(departure: trip.departureTime, arrival: trip.arrivalTime)
    timeTitleLabel.text = time.title
    timeNumberLabel.text = time.number
    timeUnitLabel.text = time.unit
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
  
  private func readableTime(departure: Date, arrival: Date) -> (title: String, number: String, unit: String) {
    
    if departure.timeIntervalSinceNow > 0 {
      let leaveIn = readableTime(from: departure.timeIntervalSinceNow)
      let title = NSLocalizedString("Leave in", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Title for when to depart. Countdown to departure will be displayed below.")
      return (title, leaveIn.number, leaveIn.unit)
    
    } else {
      let arriveIn = readableTime(from: arrival.timeIntervalSinceNow)
      let title = NSLocalizedString("Arrive in", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Title for when you'll arrive when on a trip. Countdown to arrival will be displayed below.")
      return (title, arriveIn.number, arriveIn.unit)
    }
    
  }
  
  private func readableTime(from interval: TimeInterval) -> (number: String, unit: String) {
    let mins = interval / 60
    let isFuture = mins >= 0
    let absoluteMins = mins * (isFuture ? 1 : -1)
    
    var durationString: String
    
    if absoluteMins < 60 {
      // e.g., 35m
      let rounded = Int(absoluteMins.rounded(.down))
      durationString = Date.durationString(forMinutes: rounded)
      
    } else if absoluteMins < 1440 {
      // e.g., 1h
      let hours = Int((absoluteMins/60).rounded(.down))
      durationString = Date.durationString(forHours: hours)
      
    } else {
      // e.g., 1d
      let days = Int((absoluteMins/1440).rounded(.down))
      durationString = Date.durationString(forDays: days)
    }
    
    // extract the decimal parts, e.g., start with 35m
    let number = durationString.characters // => ["3", "5", "m"]
      .flatMap { character -> String? in
        if let _ = Int(String(character)) {
          return String(character)
        } else {
          return nil
        }
      } // => ["3", "5"]
      .reduce(isFuture ? "" : "-") { $0 + $1 } // "35"
    
    // extract the unit part, e.g., start with 35m
    let unit = durationString
      .components(separatedBy: CharacterSet.decimalDigits) // => ["", "", "m"]
      .filter { !$0.isEmpty } // => ["m"]
      .reduce("") { $0 + $1 } // => "m"
    
    return (number, unit) // => ("35", "m")
  }
}

