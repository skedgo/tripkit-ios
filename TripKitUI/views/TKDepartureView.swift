//
//  TKDepartureView.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 11/09/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

public struct TKDepartureViewDestination {
  public let title: String
  public let icon: SGKImage?
  public let startTime: Date?
  public let endTime: Date?
  
  public init(title: String, icon: SGKImage? = nil, startTime: Date? = nil, endTime: Date? = nil) {
    self.title = title
    self.icon = icon
    self.startTime = startTime
    self.endTime = endTime
  }
}

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

  public func configure(for trip: STKTrip, to destination: SGTrackItemDisplayable?) {
    
    let endTime: Date?
    if let start = destination?.startDate, let duration = destination?.duration, duration > 0 {
      endTime = start.addingTimeInterval(duration)
    } else {
      endTime = nil
    }
    
    let destinationInfo = TKDepartureViewDestination(
      title: destination?.title
        ?? trip.tripPurpose
        ?? (trip as? Trip)?.request.toLocation.title
        ?? Loc.Location,
      icon: destination?.trackIcon,
      startTime: destination?.startDate,
      endTime: endTime
    )
    
    configure(for: trip, to: destinationInfo)
  }
  
  public func configure(for trip: STKTrip, to destination: TKDepartureViewDestination) {
    let segments = trip.segments(with: .inSummary)
    tripSegmentView.configure(forSegments: segments, allowSubtitles: true, allowInfoIcons: true)
    
    imageView.isHidden = false
    imageView.image = destination.icon
    destinationTitle.text = destination.title
    
    if let start = destination.startTime {
      destinationTimes.isHidden = false
      
      if let end = destination.endTime {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        destinationTimes.text = formatter.string(from: start, to: end)
      } else {
        destinationTimes.text = Loc.ArriveAt(date: SGStyleManager.timeString(start, for: nil))
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
    
    // Style
    imageView.backgroundColor = SGStyleManager.globalTintColor()
    imageView.tintColor = UIColor.white
    imageView.layer.cornerRadius = 20
    imageView.layer.masksToBounds = true
    imageView.contentMode = .center
    
    // Hide placeholders
    imageView.isHidden = true
    destinationTitle.text = nil
    destinationTimes.text = nil
    timeTitleLabel.text = nil
    timeUnitLabel.text = nil
    timeNumberLabel.text = nil
  }
  
  // MARK: - Utilities
  
  private func readableTime(departure: Date, arrival: Date) -> (title: String, number: String, unit: String) {
    
    if departure.timeIntervalSinceNow > 0 {
      let leaveIn = readableTime(from: departure.timeIntervalSinceNow)
      let title = Loc.LeaveIn
      return (title, leaveIn.number, leaveIn.unit)
    
    } else {
      let arriveIn = readableTime(from: arrival.timeIntervalSinceNow)
      let title = Loc.ArriveIn
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
    let number = durationString // => ["3", "5", "m"]
      .compactMap { character -> String? in
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

