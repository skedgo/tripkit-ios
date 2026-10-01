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
  
  /// Swapped for `segmentAtTopConstraint` when the trip hides its times, so the
  /// hidden title stack doesn't leave its gap behind. Strong, as it's removed
  /// from the view while deactivated.
  @IBOutlet var segmentBelowTitleConstraint: NSLayoutConstraint!
  
  /// Mirrors the xib's 4pt inset below the segments, rather than using the top
  /// layout margin, which only makes sense with the title above.
  private lazy var segmentAtTopConstraint = segmentView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4)
  
  /// Shows, e.g., "+1 day" next to the title, if the trip isn't on the requested day
  private let dayOffsetLabel = PaddedLabel()
  
  /// Keeps the subtitle trailing, while the day offset sticks to the title
  private let titleSpacer = UIView()
  
  private(set) var disposeBag = DisposeBag()
  
  private var formatter: Formatter?
  
  override public func awakeFromNib() {
    super.awakeFromNib()

    backgroundColor = .tkBackground
    
    titleLabel.maximumContentSizeCategory = .accessibilityLarge
    subtitleLabel.maximumContentSizeCategory = .accessibilityLarge
    
    dayOffsetLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
    dayOffsetLabel.textColor = .tkLabelSecondary
    dayOffsetLabel.backgroundColor = .tkBackgroundSecondary
    dayOffsetLabel.layer.cornerRadius = 6
    dayOffsetLabel.clipsToBounds = true
    dayOffsetLabel.maximumContentSizeCategory = .accessibilityLarge
    dayOffsetLabel.setContentHuggingPriority(.required, for: .horizontal)
    dayOffsetLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    dayOffsetLabel.isHidden = true
    
    titleSpacer.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
    titleSpacer.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
    titleLabel.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
    titleStackView.insertArrangedSubview(dayOffsetLabel, at: 1)
    titleStackView.insertArrangedSubview(titleSpacer, at: 2)
    titleStackView.setCustomSpacing(8, after: titleLabel)
    
    actionButton.titleLabel?.font = TKStyleManager.boldCustomFont(forTextStyle: .footnote)
    actionButton.tintColor = .tkAppTintColor
    
    selectionIndicator.isHidden = true
    selectionIndicator.backgroundColor = .tkAppTintColor
    
    separatorView.backgroundColor = .tkSeparatorSubtle
  }
  
  public override func prepareForReuse() {
    disposeBag = .init()
    
    super.prepareForReuse()
  }

  override public func setSelected(_ selected: Bool, animated: Bool) {
    // Not calling super, to not highlight background
    if #available(iOS 26.0, *) {
      // Outline the whole cell, which follows the corners of its section
      selectionIndicator.isHidden = true
      layer.borderWidth = selected ? 2 : 0
      layer.borderColor = UIColor.tkAppTintColor.resolvedColor(with: traitCollection).cgColor
    } else {
      selectionIndicator.isHidden = !selected
    }
  }
  
  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if #available(iOS 26.0, *) {
      layer.borderColor = UIColor.tkAppTintColor.resolvedColor(with: traitCollection).cgColor
    }
  }
  
  override public func setHighlighted(_ highlighted: Bool, animated: Bool) {
    // Not calling super to not override line colors
    UIView.animate(withDuration: animated ? 0.25 : 0) {
      self.contentView.backgroundColor = highlighted ? .tkBackgroundSelected : self.backgroundColor
    }
  }
  
  func update(preferredContentSizeCategory: UIContentSizeCategory) {
    let isVertical = preferredContentSizeCategory.isAccessibilityCategory
    titleStackView.axis = isVertical ? .vertical : .horizontal
    titleStackView.alignment = isVertical ? .leading : .center
    titleSpacer.isHidden = isVertical
  }


  // MARK: - Model
  
  func configure(_ model: Model, preferredContentSizeCategory: UIContentSizeCategory) {
    update(preferredContentSizeCategory: preferredContentSizeCategory)
    
    titleLabel.text = model.primaryTimeString
    titleLabel.font = TKStyleManager.semiboldCustomFont(forTextStyle: .headline)
    titleLabel.textColor = .tkLabelPrimary
    
    subtitleLabel.text = model.secondaryTimeString
    subtitleLabel.font = TKStyleManager.customFont(forTextStyle: .subheadline)
    subtitleLabel.textColor = .tkLabelSecondary
    
    dayOffsetLabel.text = model.dayOffsetString
    dayOffsetLabel.isHidden = model.dayOffsetString == nil
    
    titleStackView.isHidden = model.hideExactTimes
    NSLayoutConstraint.deactivate([model.hideExactTimes ? segmentBelowTitleConstraint : segmentAtTopConstraint])
    NSLayoutConstraint.activate([model.hideExactTimes ? segmentAtTopConstraint : segmentBelowTitleConstraint])
    
    segmentView.isCanceled = model.isCancelled
    segmentView.configure(model.segments, mainSegmentIndex: model.mainSegmentIndex)
    
    let alpha: CGFloat = model.showFaded ? 0.2 : 1
    titleLabel.alpha = alpha
    dayOffsetLabel.alpha = alpha
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
    
    accessibilityLabel = [model.accessibilityLabel, model.dayOffsetString].compactMap { $0 }.joined(separator: ", ")
  }
    
}

extension TKUITripCell {
  
  /// A label with some padding around its text, so that it can have a background
  fileprivate class PaddedLabel: UILabel {
    
    var insets = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
    
    override func drawText(in rect: CGRect) {
      super.drawText(in: rect.inset(by: insets))
    }
    
    override var intrinsicContentSize: CGSize {
      let size = super.intrinsicContentSize
      return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }
    
  }
  
}
