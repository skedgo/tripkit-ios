//
//  TKUITripCell.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 15.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

public class TKUITripCell: UITableViewCell {

  public static let nib = UINib(nibName: "TKUITripCell", bundle: Bundle(for: TKUITripCell.self))
  
  public static let reuseIdentifier: String = "TKUITripCell"

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var segmentView: TKUITripSegmentsView!
  @IBOutlet weak var mainSegmentActionButton: UIButton!
  @IBOutlet weak var selectionIndicator: UIView!
  @IBOutlet weak var alertIconView: UIImageView!
  @IBOutlet weak var alertActionButton: UIButton!
  
  override public func awakeFromNib() {
    super.awakeFromNib()

    backgroundColor = .tkBackground
    
    titleLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .body)
    titleLabel.textColor = .tkLabelPrimary
    
    subtitleLabel.font = TKStyleManager.customFont(forTextStyle: .subheadline)
    subtitleLabel.textColor = .tkLabelSecondary
    
    // TODO: This should be replaced
    alertIconView.backgroundColor = .systemTeal
    
    alertActionButton.tintColor = .tkAppTintColor
    alertActionButton.titleLabel?.font = TKStyleManager.boldCustomFont(forTextStyle: .footnote)
    alertActionButton.setTitle(Loc.MoreInfo, for: .normal)
    
    mainSegmentActionButton.titleLabel?.font = TKStyleManager.boldCustomFont(forTextStyle: .footnote)
    mainSegmentActionButton.tintColor = .tkAppTintColor
    
    selectionIndicator.isHidden = true
    selectionIndicator.backgroundColor = .tkAppTintColor
  }

  override public func setSelected(_ selected: Bool, animated: Bool) {
    // Not calling super, to not highlight background
    selectionIndicator.isHidden = !selected
  }
  
  override public func setHighlighted(_ highlighted: Bool, animated: Bool) {
    // Not calling super to not override line colors
    UIView.animate(withDuration: animated ? 0.25 : 0) {
      self.contentView.backgroundColor = highlighted ? .tkBackgroundSelected : self.backgroundColor
    }
  }


  // MARK: - Model
  
  public struct Model {
    public let departure: Date
    public let arrival: Date
    public let departureTimeZone: TimeZone
    public let arrivalTimeZone: TimeZone
    public let focusOnDuration: Bool
    public let isArriveBefore: Bool
    public let showFaded: Bool
    public let segments: [TKTripSegmentDisplayable]
    public let action: String?
    
    public init(departure: Date, arrival: Date, departureTimeZone: TimeZone, arrivalTimeZone: TimeZone, focusOnDuration: Bool = false, isArriveBefore: Bool = false, showFaded: Bool = false, segments: [TKTripSegmentDisplayable], action: String? = nil) {
      self.departure = departure
      self.arrival = arrival
      self.departureTimeZone = departureTimeZone
      self.arrivalTimeZone = arrivalTimeZone
      self.focusOnDuration = focusOnDuration
      self.isArriveBefore = isArriveBefore
      self.showFaded = showFaded
      self.segments = segments
      self.action = action
    }
  }
  
  public func configure(_ model: Model) {
    let formatter = Formatter()
    
    titleLabel.attributedText = formatter.primaryTimeString(departure: model.departure, arrival: model.arrival, departureTimeZone: model.departureTimeZone, arrivalTimeZone: model.arrivalTimeZone, focusOnDuration: model.focusOnDuration, isArriveBefore: model.isArriveBefore)
    
    subtitleLabel.attributedText = formatter.secondaryTimeString(departure: model.departure, arrival: model.arrival, departureTimeZone: model.departureTimeZone, arrivalTimeZone: model.arrivalTimeZone, focusOnDuration: model.focusOnDuration, isArriveBefore: model.isArriveBefore)
    
    segmentView.configure(forSegments: model.segments, allowSubtitles: true, allowInfoIcons: true)
    
    let alpha: CGFloat = model.showFaded ? 0.2 : 1
    titleLabel.alpha = alpha
    segmentView.alpha = alpha
    mainSegmentActionButton.alpha = alpha
    
    if let action = model.action {
      mainSegmentActionButton.isHidden = false
      mainSegmentActionButton.setTitle(action, for: .normal)
    } else {
      mainSegmentActionButton.isHidden = true
    }
  }
    
}
