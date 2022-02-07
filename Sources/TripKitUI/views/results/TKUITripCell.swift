//
//  TKUITripCell.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 15.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

public class TKUITripCell: UITableViewCell {

  public static let nib = UINib(nibName: "TKUITripCell", bundle: Bundle(for: TKUITripCell.self))
  
  public static let reuseIdentifier: String = "TKUITripCell"

  @IBOutlet weak var titleStackView: UIStackView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var segmentView: TKUITripSegmentsView!
  @IBOutlet weak var mainSegmentActionButton: UIButton!
  @IBOutlet weak var selectionIndicator: UIView!
  @IBOutlet weak var separatorView: UIView!
  
  @IBOutlet private weak var mainSegmentActionButtonTopSpacing: NSLayoutConstraint!
  @IBOutlet weak var mainSegmentActionButtonHeight: NSLayoutConstraint!
  
  private var formatter: Formatter?
  
  override public func awakeFromNib() {
    super.awakeFromNib()

    backgroundColor = .tkBackground
    
    formatter = Formatter()
    formatter?.primaryColor = .tkLabelPrimary
    formatter?.primaryFont = TKStyleManager.customFont(forTextStyle: .body)
    formatter?.secondaryColor = .tkLabelSecondary
    formatter?.secondaryFont = TKStyleManager.customFont(forTextStyle: .body)
    
    mainSegmentActionButton.titleLabel?.font = TKStyleManager.customFont(forTextStyle: .footnote)
    mainSegmentActionButton.tintColor = .tkAppTintColor
    
    selectionIndicator.isHidden = true
    selectionIndicator.backgroundColor = .tkAppTintColor
    
    separatorView.backgroundColor = .tkSeparatorSubtle
    
    // Allow showing it, which won't mean it'll always show it
    // - just if something is known to be inaccessible
    segmentView.allowWheelchairIcon = true
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
  
  struct Model {
    let departure: Date
    let arrival: Date
    let departureTimeZone: TimeZone
    let arrivalTimeZone: TimeZone
    let focusOnDuration: Bool
    let isArriveBefore: Bool
    let showFaded: Bool
    let isCancelled: Bool
    let hideExactTimes: Bool
    let segments: [TKUITripSegmentDisplayable]
    var action: String?
    var accessibilityLabel: String?
  }
  
  func configure(_ model: Model) {
    guard let formatter = self.formatter else { return }
    
    titleLabel.attributedText = model.hideExactTimes ? nil : formatter.primaryTimeString(departure: model.departure, arrival: model.arrival, departureTimeZone: model.departureTimeZone, arrivalTimeZone: model.arrivalTimeZone, focusOnDuration: model.focusOnDuration, isArriveBefore: model.isArriveBefore)
    
    subtitleLabel.attributedText = model.hideExactTimes ? nil : formatter.secondaryTimeString(departure: model.departure, arrival: model.arrival, departureTimeZone: model.departureTimeZone, arrivalTimeZone: model.arrivalTimeZone, focusOnDuration: model.focusOnDuration, isArriveBefore: model.isArriveBefore)
    
    segmentView.isCanceled = model.isCancelled
    segmentView.configure(model.segments)
    
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
    
    accessibilityLabel = model.accessibilityLabel
  }
    
}
