//
//  TKUIResultsTitleView.swift
//  TripKit-iOS
//
//  Created by Kuan Lun Huang on 3/10/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TGCardViewController

class TKUIResultsTitleView: UIView {
  
  @IBOutlet weak var dismissButton: UIButton!
  
  @IBOutlet weak var originLabel: UILabel!
  @IBOutlet weak var destinationLabel: UILabel!
  
  @IBOutlet private weak var topLevelStack: UIStackView!
  @IBOutlet private weak var accessoryViewContainer: UIView!
  
  @IBOutlet private weak var topLevelStackBottomSpacing: NSLayoutConstraint!
  
  var accessoryView: UIView? {
    get {
      return accessoryViewContainer.subviews.first
    }
    set {
      accessoryViewContainer.subviews.forEach { $0.removeFromSuperview() }
      
      guard let accessory = newValue else {
        accessoryViewContainer.isHidden = true
        topLevelStack.spacing = 0
        topLevelStackBottomSpacing.constant = 16
        return
      }
      
      accessoryViewContainer.isHidden = false
      topLevelStack.spacing = 16
      topLevelStackBottomSpacing.constant = 0
      
      accessoryViewContainer.addSubview(accessory)
      accessory.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
          accessory.leadingAnchor.constraint(equalTo: accessoryViewContainer.leadingAnchor),
          accessory.topAnchor.constraint(equalTo: accessoryViewContainer.topAnchor),
          accessory.trailingAnchor.constraint(equalTo: accessoryViewContainer.trailingAnchor),
          accessory.bottomAnchor.constraint(equalTo: accessoryViewContainer.bottomAnchor)
        ]
      )
    }
  }
  
  static func newInstance() -> TKUIResultsTitleView {
    return Bundle.tripKitUI.loadNibNamed("TKUIResultsTitleView", owner: self, options: nil)?.first as! TKUIResultsTitleView
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    backgroundColor = .tkBackground
    
    originLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
    originLabel.textColor = .tkLabelSecondary
    
    destinationLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .title2)
    destinationLabel.textColor = .tkLabelPrimary
    
    dismissButton.setImage(TGCard.closeButtonImage, for: .normal)
    dismissButton.setTitle(nil, for: .normal)
  }
  
  func configure(destination: String?, origin: String?) {
    destinationLabel.text = destination
    originLabel.text = origin
  }
  
}
