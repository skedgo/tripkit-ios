//
//  TKRouteNumberCell.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 20/3/18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import UIKit

class TKUIGroupedAlertCell: UITableViewCell {
  
  @IBOutlet weak var contentWrapper: UIView!
  @IBOutlet weak var modeIcon: UIImageView!
  @IBOutlet weak var serviceColorIndicator: UIView!
  @IBOutlet weak var routeNumberLabel: UILabel!
  @IBOutlet weak var routeNameLabel: UILabel!
  @IBOutlet weak var alertCountWrapper: UIView!
  @IBOutlet weak var alertCountLabel: UILabel!
  
  static var nib: UINib {
    return UINib(nibName: "TKUIGroupedAlertCell", bundle: TripKitUIBundle.bundle())
  }
  
  static var cellReuseIdentifier: String {
    return "TKUIGroupedAlertCell"
  }
  
  /// @default: `TKStyleManager.darkTextColor`
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
  var alertGroup: RouteAlerts? {
    didSet {
      updateContent()
    }
  }
  
  // MARK: -
  
  override func awakeFromNib() {
    super.awakeFromNib()
    modeIcon.tintColor = TKStyleManager.darkTextColor() // default tint.
    alertCountLabel.isHidden = true
    alertCountWrapper.isHidden = true
  }
  
  override func setHighlighted(_ highlighted: Bool, animated: Bool) {
    super.setHighlighted(highlighted, animated: animated)
    UIView.animate(withDuration: 0.25) {
      self.backgroundColor = highlighted ? TKStyleManager.cellSelectionBackgroundColor() : .white
    }
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    self.backgroundColor = selected ? TKStyleManager.cellSelectionBackgroundColor() : .white
  }
  
  // MARK: -
  
  private func updateContent() {
    guard let alertGroup = alertGroup else {
      return
    }
    
    let route = alertGroup.route
    
    // This is the generic mode image.
    let localImage = route.modeInfo.image
    
    // If we have customised mode icons on the server, use them.
    if let imageURL = route.modeInfo.imageURL {
      modeIcon.setImage(with: imageURL, asTemplate: route.modeInfo.remoteImageIsTemplate, placeholder: localImage)
    } else {
      modeIcon.image = localImage
      modeIcon.tintColor = TKStyleManager.darkTextColor()
    }
    
    serviceColorIndicator.backgroundColor = route.color
    
    routeNumberLabel.text = route.number ?? route.name
    routeNumberLabel.font = TKStyleManager.semiboldCustomFont(forTextStyle: .body)
    routeNameLabel.text = route.name
    routeNameLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
    routeNameLabel.isHidden = (route.name == nil) || (routeNameLabel.text == routeNumberLabel.text)
    
    let multipleAlerts = alertGroup.alerts.count > 1
    
    alertCountWrapper.isHidden = !multipleAlerts
    alertCountLabel.isHidden = !multipleAlerts
    alertCountLabel.font = TKStyleManager.systemFont(size: 15)
    
    alertCountLabel.text = multipleAlerts ? "\(alertGroup.alerts.count)" : nil
    if alertGroup.alerts(ofType: .alert).count != 0 {
      alertCountWrapper.backgroundColor = #colorLiteral(red: 0.8784313725, green: 0.2823529412, blue: 0.2823529412, alpha: 1)
    } else {
      alertCountWrapper.backgroundColor = #colorLiteral(red: 0.937254902, green: 0.8274509804, blue: 0.2352941176, alpha: 1)
    }
  }
  
}
