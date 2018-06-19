//
//  TKTripCell.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 15.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

public class TKTripCell: UITableViewCell {

  public static let nib = UINib(nibName: "TKTripCell", bundle: Bundle(for: TKTripCell.self))
  
  public static let reuseIdentifier: String = "TKTripCell"

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var segmentView: SGTripSegmentsView!
  @IBOutlet weak var actionButton: UIButton!
  
  private var formatter: Formatter?
  
  override public func awakeFromNib() {
    super.awakeFromNib()
    
    formatter = Formatter()
    formatter?.primaryColor = SGStyleManager.darkTextColor()
    formatter?.primaryFont = titleLabel.font
    formatter?.secondaryColor = SGStyleManager.lightTextColor()
    formatter?.secondaryFont = titleLabel.font
  }

  override public func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }
}

// MARK: - Model {

extension TKTripCell {

  public struct Model {
    public let departure: Date
    public let arrival: Date
    public let departureTimeZone: TimeZone
    public let arrivalTimeZone: TimeZone
    public let focusOnDuration: Bool
    public let isArriveBefore: Bool
    
    public let segments: [STKTripSegmentDisplayable]
    
    public let alert: String?
    
    public init(departure: Date, arrival: Date, departureTimeZone: TimeZone, arrivalTimeZone: TimeZone, focusOnDuration: Bool = false, isArriveBefore: Bool = false, segments: [STKTripSegmentDisplayable], alert: String? = nil) {
      self.departure = departure
      self.arrival = arrival
      self.departureTimeZone = departureTimeZone
      self.arrivalTimeZone = arrivalTimeZone
      self.focusOnDuration = focusOnDuration
      self.isArriveBefore = isArriveBefore
      self.segments = segments
      self.alert = alert
    }
  }
  
  public func configure(_ model: Model) {
    guard let formatter = formatter else { preconditionFailure() }
    
    titleLabel.attributedText = formatter.timeString(departure: model.departure, arrival: model.arrival, departureTimeZone: model.departureTimeZone, arrivalTimeZone: model.arrivalTimeZone, focusOnDuration: model.focusOnDuration, isArriveBefore: model.isArriveBefore)
    
    segmentView.configure(forSegments: model.segments, allowSubtitles: true, allowInfoIcons: true)
    
    if let alert = model.alert {
      actionButton.isHidden = false
      actionButton.setTitle(alert, for: .normal)
    } else {
      actionButton.isHidden = true
    }
  }
    
}
