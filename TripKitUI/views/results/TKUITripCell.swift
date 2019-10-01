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

  @IBOutlet private weak var mainSegmentActionButtonTopSpacing: NSLayoutConstraint!
  @IBOutlet weak var mainSegmentActionButtonHeight: NSLayoutConstraint!
  
  private var formatter: Formatter?
  
  override public func awakeFromNib() {
    super.awakeFromNib()

    backgroundColor = .tkBackground
    
    formatter = Formatter()
    formatter?.primaryColor = .tkLabelPrimary
    formatter?.primaryFont = TKStyleManager.boldCustomFont(forTextStyle: .body)
    formatter?.secondaryColor = .tkLabelSecondary
    formatter?.secondaryFont = TKStyleManager.boldCustomFont(forTextStyle: .body)
    
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
    guard let formatter = self.formatter else { return }
    
    titleLabel.attributedText = formatter.primaryTimeString(departure: model.departure, arrival: model.arrival, departureTimeZone: model.departureTimeZone, arrivalTimeZone: model.arrivalTimeZone, focusOnDuration: model.focusOnDuration, isArriveBefore: model.isArriveBefore)
    
    subtitleLabel.attributedText = formatter.secondaryTimeString(departure: model.departure, arrival: model.arrival, departureTimeZone: model.departureTimeZone, arrivalTimeZone: model.arrivalTimeZone, focusOnDuration: model.focusOnDuration, isArriveBefore: model.isArriveBefore)
    
    segmentView.configure(forSegments: model.segments, allowSubtitles: true, allowInfoIcons: true)
    
    let alpha: CGFloat = model.showFaded ? 0.2 : 1
    titleLabel.alpha = alpha
    segmentView.alpha = alpha
    mainSegmentActionButton.alpha = alpha
    
    if let action = model.action {
      mainSegmentActionButton.isHidden = false
      mainSegmentActionButtonTopSpacing.constant = 4
      mainSegmentActionButton.setTitle(action, for: .normal)
      mainSegmentActionButtonHeight.constant = mainSegmentActionButton.intrinsicContentSize.height
    } else {
      mainSegmentActionButton.isHidden = true
      mainSegmentActionButtonTopSpacing.constant = 0
      mainSegmentActionButtonHeight.constant = 0
    }
  }
    
}
