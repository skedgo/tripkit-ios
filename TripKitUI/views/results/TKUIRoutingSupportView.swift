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
  
  @IBOutlet weak var requestSupportButtonTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var requestSupportButtonHeightConstraint: NSLayoutConstraint!
  
  // MARK: - Factory
  
  public static func makeView(with message: NSAttributedString, allowRoutingRequest: Bool) -> TKUIRoutingSupportView {
    guard let supportView = Bundle(for: self).loadNibNamed(String(describing: self), owner: self, options: nil)?.first as? TKUIRoutingSupportView else {
      preconditionFailure("Unable to load view from nib")
    }
    
    supportView.backgroundColor = .tkBackground
    
    // Image view
    supportView.imageView.contentMode = .center
    supportView.imageView.image = .iconTripBoyWorker
    
    // Label
    supportView.textLabel.textAlignment = .center
    supportView.textLabel.attributedText = message
    
    // Top button
    supportView.requestSupportButtonTopConstraint.constant = allowRoutingRequest ? 50 : 0
    supportView.requestSupportButtonHeightConstraint.constant = allowRoutingRequest ? 45: 0
    supportView.requestSupportButton.isHidden = !allowRoutingRequest
    
    if allowRoutingRequest {
      supportView.requestSupportButton.layer.cornerRadius = 8
      supportView.requestSupportButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 24, bottom: 8, right: 24)
      supportView.requestSupportButton.setTitle(Loc.RequestSupport.uppercased(), for: .normal)
      supportView.requestSupportButton.backgroundColor = TKStyleManager.globalTintColor()
      supportView.requestSupportButton.tintColor = .tkBackground
    }
    
    // Bottom button
    supportView.planNewTripButton.setTitle(Loc.PlanANewTrip.uppercased(), for: .normal)
    supportView.planNewTripButton.backgroundColor = .clear
    supportView.planNewTripButton.tintColor = TKStyleManager.globalTintColor()
    
    // Both buttons
    supportView.requestSupportButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .heavy)
    supportView.planNewTripButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
    
    return supportView
  }
  
}
