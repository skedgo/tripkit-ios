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
  @IBOutlet weak var modeIcon: UIImageView!
  @IBOutlet weak var serviceColorIndicator: UIView!
  @IBOutlet weak var routeNumberLabel: UILabel!
  @IBOutlet weak var routeNameLabel: UILabel!
  
  @IBOutlet private weak var contentWrapperTopConstraint: NSLayoutConstraint!
  @IBOutlet private weak var contentWrapperBottomConstraint: NSLayoutConstraint!
  
  /// @default: `SGStyleManager.darkTextColor`
  var cellTextColor: UIColor? {
    willSet {
      routeNumberLabel.textColor = newValue
      routeNameLabel.textColor = newValue
      modeIcon.tintColor = newValue
    }
  }
  
  var route: API.Route? {
    didSet {
      updateContent()
    }
  }
  
  // MARK: -
  
  override func setHighlighted(_ highlighted: Bool, animated: Bool) {
    super.setHighlighted(highlighted, animated: animated)
    UIView.animate(withDuration: 0.25) {
      self.backgroundColor = highlighted ? SGStyleManager.cellSelectionBackgroundColor() : .white
    }
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    self.backgroundColor = selected ? SGStyleManager.cellSelectionBackgroundColor() : .white
  }
  
  // MARK: -
  
  private func updateContent() {
    guard let route = route else { return }
    
    modeIcon.image = SGStyleManager.image(forModeImageName: route.modeInfo.localImageName, isRealTime: false, of: .listMainMode)
    modeIcon.tintColor = cellTextColor ?? SGStyleManager.darkTextColor()
    serviceColorIndicator.backgroundColor = route.modeInfo.color
    
    routeNumberLabel.text = route.number ?? route.name
    routeNumberLabel.textColor = cellTextColor ?? SGStyleManager.darkTextColor()
    
    routeNameLabel.text = route.name
    routeNameLabel.textColor = cellTextColor ?? SGStyleManager.lightTextColor()
    routeNameLabel.isHidden = (route.name == nil) || (routeNameLabel.text == routeNumberLabel.text)
  }
  
  override func updateConstraints() {
    super.updateConstraints()
    contentWrapperTopConstraint.constant = 0
    contentWrapperBottomConstraint.constant = 0
  }
  
}
