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
  @IBOutlet weak var routeNameLabel: UILabel!
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
  
  // FIXME: This only works for RACV!!!
  var mode: String? {
    didSet {
      routeNumberLabel.textColor = .white
      
      guard let mode = mode else {
        routeNumberWrapper.backgroundColor = SGStyleManager.globalTintColor()
        return
      }
      
      switch mode {
      case "pt_pub_train":
        routeNumberWrapper.backgroundColor = #colorLiteral(red: 0, green: 0.4470588235, blue: 0.8078431373, alpha: 1)
      case "pt_pub_bus":
        routeNumberWrapper.backgroundColor = #colorLiteral(red: 1, green: 0.5098039216, blue: 0.003921568627, alpha: 1)
      case "pt_pub_tram":
        routeNumberWrapper.backgroundColor = #colorLiteral(red: 0.4705882353, green: 0.7450980392, blue: 0.1294117647, alpha: 1)
      default:
        routeNumberWrapper.backgroundColor = SGStyleManager.globalTintColor()
      }
    }
  }
  
  override func awakeFromNib() {
    backgroundColor = SGStyleManager.backgroundColorForTileList()
    infoIcon.tintColor = SGStyleManager.globalTintColor()
    alertCountLabel.textColor = SGStyleManager.globalTintColor()
  }
  
  private func updateContent() {
    guard let route = route else { return }
    
    routeNumberLabel.text = route.number
    routeNumberWrapper.isHidden = route.number?.isEmpty ?? true
    
    routeNameLabel.text = route.name
    routeNameLabel.isHidden = route.name?.isEmpty ?? true
  }
  
  override func updateConstraints() {
    super.updateConstraints()
    contentWrapperTopConstraint.constant = 0.5
    contentWrapperBottomConstraint.constant = 0.5
  }
  
}
