//
//  TKUISegmentAlertCell.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 10/12/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TKUISegmentAlertCell: UITableViewCell {
  
  @IBOutlet private weak var contentWrapper: UIView!
  @IBOutlet private weak var lineWrapper: UIView!
  
  @IBOutlet weak var line: UIView!
  @IBOutlet weak var iconView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var chevronView: UIImageView!
  
  static let nib = UINib(nibName: "TKUISegmentAlertCell", bundle: Bundle(for: TKUISegmentAlertCell.self))
  
  static let reuseIdentifier = "TKUISegmentAlertCell"

  override func awakeFromNib() {
    super.awakeFromNib()
    
    backgroundColor = .tkBackground

    // Same styling as in TKUIServiceHeaderView
    contentWrapper.layer.borderWidth = 1.0
    contentWrapper.layer.cornerRadius = 6.0
    if #available(iOSApplicationExtension 13.0, *) {
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
    
    titleLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .footnote)
    titleLabel.textColor = .tkLabelPrimary
    
//    subtitleLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
//    subtitleLabel.textColor = .tkLabelPrimary
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
    titleLabel.text = item.title
//    subtitleLabel.text = item.subtitles.joined("\n")
  }
  
}
