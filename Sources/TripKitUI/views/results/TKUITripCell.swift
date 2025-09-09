//
//  TKUITripCell.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 15.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift
import TripKit

public class TKUITripCell: UITableViewCell {

  public static let nib = UINib(nibName: "TKUITripCell", bundle: .tripKitUI)
  
  public static let reuseIdentifier: String = "TKUITripCell"

  @IBOutlet weak var titleStackView: UIStackView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var segmentView: TKUITripSegmentsView!
  @IBOutlet weak var selectionIndicator: UIView!
  @IBOutlet weak var separatorView: UIView!
  
  @IBOutlet var segmentTrailingConstraint: NSLayoutConstraint!
  @IBOutlet var segmentToActionConstraint: NSLayoutConstraint!
  @IBOutlet var actionButton: UIButton!
  
  private(set) var disposeBag = DisposeBag()
  
  private var formatter: Formatter?
  
  override public func awakeFromNib() {
    super.awakeFromNib()

    backgroundColor = .tkBackground
    
    titleLabel.maximumContentSizeCategory = .accessibilityLarge
    subtitleLabel.maximumContentSizeCategory = .accessibilityLarge
    
    actionButton.titleLabel?.font = TKStyleManager.boldCustomFont(forTextStyle: .footnote)
    actionButton.tintColor = .tkAppTintColor
    
    selectionIndicator.isHidden = true
    selectionIndicator.backgroundColor = .tkAppTintColor
    
    separatorView.backgroundColor = .tkSeparatorSubtle
    
    // Allow showing it, which won't mean it'll always show it
    // - just if something is known to be inaccessible
    segmentView.allowWheelchairIcon = true
    segmentView.allowBicycleAccessibilityIcon = true
  }
  
  public override func prepareForReuse() {
    disposeBag = .init()
    
    super.prepareForReuse()
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
  
  func update(preferredContentSizeCategory: UIContentSizeCategory) {
    titleStackView.axis = preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
  }


  // MARK: - Model
  
  func configure(_ model: Model, preferredContentSizeCategory: UIContentSizeCategory) {
    update(preferredContentSizeCategory: preferredContentSizeCategory)
    
    titleLabel.text = model.hideExactTimes ? nil : TKUITripCell.Formatter.primaryTimeString(departure: model.departure, arrival: model.arrival, departureTimeZone: model.departureTimeZone, arrivalTimeZone: model.arrivalTimeZone, focusOnDuration: model.focusOnDuration, isArriveBefore: model.isArriveBefore)
    titleLabel.font = TKStyleManager.semiboldCustomFont(forTextStyle: .headline)
    titleLabel.textColor = .tkLabelPrimary
    
    subtitleLabel.text = model.hideExactTimes ? nil : TKUITripCell.Formatter.secondaryTimeString(departure: model.departure, arrival: model.arrival, departureTimeZone: model.departureTimeZone, arrivalTimeZone: model.arrivalTimeZone, focusOnDuration: model.focusOnDuration, isArriveBefore: model.isArriveBefore)
    subtitleLabel.font = TKStyleManager.customFont(forTextStyle: .subheadline)
    subtitleLabel.textColor = .tkLabelSecondary
    
    segmentView.isCanceled = model.isCancelled
    segmentView.configure(model.segments)
    
    let alpha: CGFloat = model.showFaded ? 0.2 : 1
    titleLabel.alpha = alpha
    segmentView.alpha = alpha
    actionButton.alpha = alpha
    
    if let action = model.primaryAction {
      actionButton.isHidden = false
      actionButton.setTitle(action, for: .normal)
      segmentTrailingConstraint.priority = .defaultLow
      segmentToActionConstraint.priority = .required
    } else {
      actionButton.isHidden = true
      actionButton.setTitle("", for: .normal)
      segmentTrailingConstraint.priority = .required
      segmentToActionConstraint.priority = .defaultLow
    }
    
    accessibilityLabel = model.accessibilityLabel
  }
    
}
