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
  
  static let nib = UINib(nibName: "TKUISegmentAlertCell", bundle: Bundle(for: TKUISegmentAlertCell.self))
  
  static let reuseIdentifier = "TKUISegmentAlertCell"

  override func awakeFromNib() {
    super.awakeFromNib()
    
    contentWrapper.layer.borderWidth = 1.0
    contentWrapper.layer.borderColor = #colorLiteral(red: 0.7490196078, green: 0.8509803922, blue: 0.9921568627, alpha: 1)
    contentWrapper.layer.cornerRadius = 6.0
    contentWrapper.backgroundColor = #colorLiteral(red: 0.9294117647, green: 0.9607843137, blue: 0.9921568627, alpha: 1)
    
    titleLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
    titleLabel.textColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
    
    subtitleLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
    subtitleLabel.textColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
  
  override func setHighlighted(_ highlighted: Bool, animated: Bool) {
    UIView.animate(withDuration: animated ? 0.25 : 0) {
      self.contentWrapper.backgroundColor = highlighted ? #colorLiteral(red: 0.05987539297, green: 0.5114932569, blue: 0.8331292794, alpha: 0.5) : #colorLiteral(red: 0.9294117647, green: 0.9607843137, blue: 0.9921568627, alpha: 1)
    }
  }
    
}

extension TKUISegmentAlertCell {
  
  func configure(with item: TKUITripOverviewViewModel.AlertItem) {
    let hasLine = item.connection?.color != nil
    line.backgroundColor = item.connection?.color
    line.isHidden = !hasLine
    
    iconView.image = item.icon ?? item.defaultIcon
    titleLabel.text = item.title ?? item.defaultTitle
    subtitleLabel.text = item.subtitle ?? item.defaultSubtitle
  }
  
}

extension TKUITripOverviewViewModel.AlertItem {
  
  var defaultIcon: UIImage? { TKInfoIcon.image(for: .warning, usage: .normal) }
  var defaultTitle: String { Loc.Information }
  var defaultSubtitle: String? { alerts.count == 1 ? nil : Loc.Alerts(alerts.count) }
  
}

