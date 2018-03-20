//
//  TKRouteNumberCell.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 20/3/18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import UIKit

class TKRouteNumberCell: UITableViewCell {
  
  @IBOutlet weak var contentWrapper: UIView!
  @IBOutlet weak var routeNumberLabel: UILabel!
  @IBOutlet weak var routeNameLabel: UILabel!
  @IBOutlet private weak var routeNameLabelLeadingSpaceConstraint: NSLayoutConstraint!
  
  var route: API.Route? {
    didSet {
      updateContent()
    }
  }
  
  override func awakeFromNib() {
    backgroundColor = SGStyleManager.backgroundColorForTileList()
    SGStyleManager.addDefaultOutline(contentWrapper)
  }
  
  private func updateContent() {
    guard let route = route else { return }
    routeNumberLabel.text = route.number
    routeNameLabel.text = route.name
  }
  
  override func updateConstraints() {
    super.updateConstraints()
    guard let route = route else { return }
    let hasRouteNumber = route.number != nil
    routeNameLabelLeadingSpaceConstraint.constant = hasRouteNumber ? 8 : 0
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    routeNameLabelLeadingSpaceConstraint.constant = 8
  }
  
}
