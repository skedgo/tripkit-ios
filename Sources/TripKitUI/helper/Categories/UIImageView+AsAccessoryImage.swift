//
//  UIImageView+AsAccessoryImage.swift
//  TripKit
//
//  Created by Adrian Schoenig on 7/08/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

extension UIImageView {
  convenience init(asRealTimeAccessoryImageAnimated animated: Bool, tintColor: UIColor? = nil) {
    self.init()
    
    let images = UIImageView.realTimeAccessoryImage(animated)
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
    if let tintColor {
      self.tintColor = tintColor
    }
  }
  
  private static func realTimeAccessoryImage(_ animated: Bool) -> [UIImage] {
    if #available(iOS 16.0, *), animated {
      let image1 = UIImage(systemName: "dot.radiowaves.forward", variableValue: 0.3)
      let image2 = UIImage(systemName: "dot.radiowaves.forward", variableValue: 0.7)
      let image3 = UIImage(systemName: "dot.radiowaves.forward", variableValue: 1.0)
      return [image1, image2, image3, image3, image3, image3, image3, image3].compactMap { $0 }
      
    } else if #available(iOS 14.0, *) {
      // Right-pointing, all bars
      return [UIImage(systemName: "dot.radiowaves.forward")].compactMap { $0 }
      
    } else {
      // Up-pointing, like wifi, all bars
      return [UIImage(systemName: "wifi")].compactMap { $0 }
    }
  }
}
