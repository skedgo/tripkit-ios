//
//  TKUISegmentAlertCell.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 10/12/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

class TKUISegmentAlertCell: UITableViewCell {
  
  @IBOutlet private weak var contentWrapper: UIView!
  @IBOutlet private weak var lineWrapper: UIView!
  
  @IBOutlet weak var line: UIView!
  @IBOutlet weak var iconView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var actionButton: UIButton!
  
  var disposeBag = DisposeBag()
  
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
    
    actionButton.setTitleColor(#colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1), for: .normal)
    actionButton.titleLabel?.font = TKStyleManager.customFont(forTextStyle: .footnote)
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    // Configure the view for the selected state
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    disposeBag = DisposeBag()
  }
    
}

extension TKUISegmentAlertCell {
  
  func configure(with item: TKUITripOverviewViewModel.AlertItem) {
    let hasLine = item.connection?.color != nil
    line.backgroundColor = item.connection?.color
    line.isHidden = !hasLine
    
    iconView.image = item.icon ?? item.defaultIcon
    titleLabel.text = item.title ?? item.defaultTitle
    actionButton.setTitle(item.actionTitle ?? item.defaultActionTitle, for: .normal)
  }
  
}

extension TKUITripOverviewViewModel.AlertItem {
  
  var defaultIcon: UIImage? { TKInfoIcon.image(for: .warning, usage: .normal) }
  var defaultTitle: String { "Information" }
  var defaultActionTitle: String { alerts.count == 1 ? "1 alert" : "\(alerts.count) alerts" }
  
}

