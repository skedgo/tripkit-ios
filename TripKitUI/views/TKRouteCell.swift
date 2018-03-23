//
//  TKRouteNumberCell.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 20/3/18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import UIKit

class TKRouteCell: UITableViewCell {
  
  @IBOutlet weak var contentWrapper: UIView!
  @IBOutlet weak var routeNumberLabel: UILabel!
  @IBOutlet weak var infoIcon: UIImageView!
  @IBOutlet weak var alertCountLabel: UILabel!
  @IBOutlet weak var serviceColorIndicator: UIView!
  
  @IBOutlet private weak var contentWrapperTopConstraint: NSLayoutConstraint!
  @IBOutlet private weak var contentWrapperBottomConstraint: NSLayoutConstraint!
  
  var route: API.Route? {
    didSet {
      updateContent()
    }
  }
  
  var alertCount: Int? {
    didSet {
      guard let value = alertCount else {
        alertCountLabel.isHidden = true
        return
      }
      alertCountLabel.isHidden = false
      alertCountLabel.text = "\(value)"
    }
  }
  
  // MARK: -
  
  override func awakeFromNib() {
    backgroundColor = SGStyleManager.backgroundColorForTileList()
    infoIcon.tintColor = SGStyleManager.globalTintColor()
    alertCountLabel.textColor = SGStyleManager.globalTintColor()
  }
  
  override func setHighlighted(_ highlighted: Bool, animated: Bool) {
    super.setHighlighted(highlighted, animated: animated)
    UIView.animate(withDuration: 0.1) {
      self.contentWrapper.backgroundColor = highlighted ? SGStyleManager.cellSelectionBackgroundColor() : .white
    }
  }
  
  // MARK: -
  
  private func updateContent() {
    guard let route = route else { return }
    
    routeNumberLabel.text = route.number ?? route.name
    serviceColorIndicator.backgroundColor = route.modeInfo.color
  }
  
  override func updateConstraints() {
    super.updateConstraints()
    contentWrapperTopConstraint.constant = 0
    contentWrapperBottomConstraint.constant = 0
  }
  
}
