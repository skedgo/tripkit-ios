//
//  TKUISegmentAlertCell.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 10/12/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

#if SWIFT_PACKAGE
import TripKitObjc
#endif

class TKUISegmentAlertCell: UITableViewCell {
  
  @IBOutlet private weak var contentWrapper: UIView!
  @IBOutlet private weak var lineWrapper: UIView!
  
  @IBOutlet weak var line: UIView!
  @IBOutlet weak var iconView: UIImageView!
  @IBOutlet weak var alertCountLabel: UILabel!
  @IBOutlet weak var chevronView: UIImageView!
  @IBOutlet weak var titlesStackView: UIStackView!
  
  static let nib = UINib(nibName: "TKUISegmentAlertCell", bundle: Bundle(for: TKUISegmentAlertCell.self))
  
  static let reuseIdentifier = "TKUISegmentAlertCell"

  override func awakeFromNib() {
    super.awakeFromNib()
    
    backgroundColor = .clear

    // Same styling as in TKUIServiceHeaderView
    contentWrapper.layer.borderWidth = 1.0
    contentWrapper.layer.cornerRadius = 6.0
    if #available(iOS 13.0, *) {
      contentWrapper.backgroundColor = UIColor { _ in UIColor.tkStateWarning.withAlphaComponent(0.12) }
      contentWrapper.layer.borderColor = UIColor { traits in
        switch traits.userInterfaceStyle {
        case .dark: return UIColor.tkStateWarning.withAlphaComponent(0.3)
        default:    return UIColor.tkStateWarning.withAlphaComponent(0.6)
        }
      }.cgColor

    } else {
      contentWrapper.backgroundColor = UIColor.tkStateWarning.withAlphaComponent(0.12)
      contentWrapper.layer.borderColor = UIColor.tkStateWarning.withAlphaComponent(0.6).cgColor
    }
    
    iconView.tintColor = .tkStateWarning
    chevronView.tintColor = .tkLabelPrimary
    
    alertCountLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .footnote)
    alertCountLabel.textColor = .tkLabelPrimary
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
  
  override func setHighlighted(_ highlighted: Bool, animated: Bool) {
    UIView.animate(withDuration: animated ? 0.25 : 0) {
      self.contentWrapper.alpha = highlighted ? 0.3 : 1
    }
  }
    
}

extension TKUISegmentAlertCell {
  
  func configure(with item: TKUITripOverviewViewModel.AlertItem) {
    let hasLine = item.connection?.color != nil
    line.backgroundColor = item.connection?.color
    line.isHidden = !hasLine
    
    iconView.tintColor = item.isCritical ? .tkStateError : .tkStateWarning
    alertCountLabel.text = Loc.Alerts(item.alerts.count)
    addTitles(from: item.alerts)
  }
  
  private func resetTitles() {
    titlesStackView.arrangedSubviews.forEach {
      titlesStackView.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }
  }
  
  private func addTitles(from alerts: [Alert]) {
    // Make sure we start clean
    resetTitles()
    
    alerts
      .flatMap { alert -> [UIView] in
        // Add a separator before title
        let separator = UIView()
        separator.backgroundColor = .tkSeparator
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return [separator, titleStack(for: alert)]
      }
      .enumerated()
      .forEach { index, view in
        // We multiply by 2 here because each "title" is consisted of a
        // preceding separator and the title label.
        guard index < TKUITripOverviewCard.config.maximumAlertsPerSegment*2 else { return }
        titlesStackView.addArrangedSubview(view)
      }
  }
  
  private func titleStack(for alert: Alert) -> UIStackView {
    let stack = UIStackView()
    stack.axis = .horizontal
    stack.alignment = .center
    stack.distribution = .fill
    
    let label = UILabel()
    label.font = TKStyleManager.customFont(forTextStyle: .footnote)
    label.textColor = .tkLabelPrimary
    label.text = alert.title
    label.numberOfLines = 2
    label.translatesAutoresizingMaskIntoConstraints = false
    stack.addArrangedSubview(label)
    
    return stack
  }
  
}
