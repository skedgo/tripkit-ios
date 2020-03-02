//
//  UIImageView+AsAccessoryImage.swift
//  TripKit
//
//  Created by Adrian Schoenig on 7/08/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

/// :nodoc:
public extension UIImageView {
  @objc convenience init(asRealTimeAccessoryImageAnimated animated: Bool, tintColor: UIColor? = nil) {
    self.init()
    
    let images = UIImageView.realTimeAccessoryImage(animated, tintColor: tintColor)
    if animated {
      self.image = images.last
      self.animationImages = images
      self.animationDuration = 1
      self.animationRepeatCount = 2
      self.startAnimating()
      
    } else {
      self.image = images.first
    }
    self.accessibilityLabel = Loc.RealTime
  }
  
  private static func realTimeAccessoryImage(_ animated: Bool, tintColor: UIColor? = nil) -> [UIImage] {
    if animated {
      var image1 = TripKitUIBundle.imageNamed("icon-signal-bars1")
      var image2 = TripKitUIBundle.imageNamed("icon-signal-bars2")
      var image3 = TripKitUIBundle.imageNamed("icon-signal-bars3")
      
      if let tintColor = tintColor {
        image1 = image1.tk_image(withTintColor: tintColor)
        image2 = image2.tk_image(withTintColor: tintColor)
        image3 = image3.tk_image(withTintColor: tintColor)
      }
      return [image1, image2, image3, image3, image3, image3, image3, image3]
    } else {
      return [TripKitUIBundle.imageNamed("icon-signal-bars3")]
    }
  }
}
