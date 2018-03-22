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
  @IBOutlet weak var routeNumberWrapper: UIView!
  
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
  
  override func awakeFromNib() {
    backgroundColor = SGStyleManager.backgroundColorForTileList()
    infoIcon.tintColor = SGStyleManager.globalTintColor()
    alertCountLabel.textColor = SGStyleManager.globalTintColor()
  }
  
  private func updateContent() {
    guard let route = route else { return }
    
    routeNumberLabel.text = route.number ?? route.name
    
    if let color = route.modeInfo.color {
      routeNumberWrapper.backgroundColor = color
      routeNumberLabel.textColor = .white
    } else {
      routeNumberWrapper.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
    }
  }
  
  override func updateConstraints() {
    super.updateConstraints()
    contentWrapperTopConstraint.constant = 0
    contentWrapperBottomConstraint.constant = 0
  }
  
}
