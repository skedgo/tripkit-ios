//
//  TKUITripBoyView.swift
//  TripKitUI
//
//  Created by Adrian Schoenig on 13/12/16.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

public class TKUITripBoyView: UIView {

  @IBOutlet weak var tripBoyImageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet public weak var actionButton: UIButton!
  @IBOutlet public weak var retryButton: UIButton!
  
  public class func newInstance() -> TKUITripBoyView {
    let view = Bundle(for: self).loadNibNamed("TKUITripBoyView", owner: self, options: nil)?.first as! TKUITripBoyView
    return view
  }

  public func configure(title: String?, description: String?, actionTitle: String?, isHappy: Bool, allowRetry: Bool) {
    
    backgroundColor = TKStyleManager.backgroundColorForTileList()
    
    titleLabel.text = title
    descriptionLabel.text = description
    
    if let action = actionTitle {
      actionButton.setTitle(action, for: .normal)
      actionButton.isHidden = false
    } else {
      actionButton.isHidden = true
    }
    
    if isHappy {
      tripBoyImageView.image = .iconTripBoyHappy
    } else {
      tripBoyImageView.image = .iconTripBoySad
    }
    
    if allowRetry {
      retryButton.isHidden = false
    } else {
      retryButton.isHidden = true
    }
  }
  
  static func clear(from view: UIView) {
    view.subviews
      .filter { $0 is TKUITripBoyView }
      .forEach { $0.removeFromSuperview() }
  }

  @discardableResult
  public class func show(error: Error, title: String? = nil, in view: UIView, aboveSubview: UIView? = nil, actionTitle: String? = nil) -> TKUITripBoyView {
    self.clear(from: view)

    let tripBoy = TKUITripBoyView.newInstance()
    tripBoy.configure(title: title, description: error.localizedDescription, actionTitle: actionTitle, isHappy: false, allowRetry: false)
    
    tripBoy.backgroundColor = TKStyleManager.backgroundColorForTileList()
    tripBoy.translatesAutoresizingMaskIntoConstraints = false
    if let above = aboveSubview {
      view.insertSubview(tripBoy, aboveSubview: above)
    } else {
      view.addSubview(tripBoy)
    }
    
    tripBoy.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
    tripBoy.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    view.trailingAnchor.constraint(equalTo: tripBoy.trailingAnchor).isActive = true
    view.bottomAnchor.constraint(equalTo: tripBoy.bottomAnchor).isActive = true
    
    return tripBoy
  }
  
}
