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
  
  /// @default: `SGStyleManager.darkTextColor`
  var cellTextColor: UIColor? {
    willSet {
      routeNumberLabel.textColor = newValue
      routeNameLabel.textColor = newValue
      modeIcon.tintColor = newValue
    }
  }
  
  /// This is the main configuration point. Setting this property updates
  /// the cell content. Note that, cell appearance such as text and tint
  /// colors are not updated here. Instead, use other appearance properties
  /// e.g., `cellTextColor`.
  var route: API.Route? {
    didSet {
      updateContent()
    }
  }
  
  // MARK: -
  
  override func awakeFromNib() {
    modeIcon.tintColor = SGStyleManager.darkTextColor() // default tint.
  }
  
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
    
    // This is the generic mode image.
    let localImage = SGStyleManager.image(forModeImageName: route.modeInfo.localImageName, isRealTime: false, of: .listMainMode)
    
    // If we have customised mode icons on the server, use them.
    if let remoteImageName = route.modeInfo.remoteImageName {
      let remoteImageURL = SVKServer.imageURL(forIconFileNamePart: remoteImageName, of: .listMainMode)
      modeIcon.setImage(with: remoteImageURL, asTemplate: route.modeInfo.remoteImageIsTemplate, placeholder: localImage)
    }
    
    serviceColorIndicator.backgroundColor = route.color
    routeNumberLabel.text = route.number ?? route.name
    routeNameLabel.text = route.name
    routeNameLabel.isHidden = (route.name == nil) || (routeNameLabel.text == routeNumberLabel.text)
  }
  
}
