//
//  TKUIRoutingSupportView.swift
//  TripGo
//
//  Created by Kuan Lun Huang on 7/11/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

public class TKUIRoutingSupportView: UIView {
  
  @IBOutlet weak var textLabel: UILabel!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet public internal(set) weak var requestSupportButton: UIButton!
  @IBOutlet public internal(set) weak var planNewTripButton: UIButton!
  
  // MARK: - Factory
  
  public class func makeView(with message: NSAttributedString) -> TKUIRoutingSupportView {
    guard let supportView = Bundle(for: self).loadNibNamed(String(describing: self), owner: self, options: nil)?.first as? TKUIRoutingSupportView else {
      preconditionFailure("Unable to load view from nib")
    }
    
    // Image view
    supportView.imageView.contentMode = .center
    supportView.imageView.image = .iconTripBoyWorker
    
    // Label
    supportView.textLabel.textAlignment = .center
    supportView.textLabel.attributedText = message
    
    // Top button
    
    supportView.requestSupportButton.layer.cornerRadius = 8
    supportView.requestSupportButton.contentEdgeInsets = UIEdgeInsetsMake(8, 24, 8, 24)
    supportView.requestSupportButton.setTitle(Loc.RequestSupport.uppercased(), for: .normal)
    supportView.requestSupportButton.backgroundColor = SGStyleManager.globalTintColor()
    supportView.requestSupportButton.tintColor = .white
    
    // Bottom button
    
    supportView.planNewTripButton.setTitle(Loc.PlanANewTrip.uppercased(), for: .normal)
    supportView.planNewTripButton.backgroundColor = .clear
    supportView.planNewTripButton.tintColor = SGStyleManager.globalTintColor()
    
    // Both buttons
    
    supportView.requestSupportButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .heavy)
    supportView.planNewTripButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
    
    return supportView
  }
  
}
