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
        image1 = image1.applying(tintColor: tintColor)
        image2 = image2.applying(tintColor: tintColor)
        image3 = image3.applying(tintColor: tintColor)
      }
      return [image1, image2, image3, image3, image3, image3, image3, image3]
    } else {
      return [TripKitUIBundle.imageNamed("icon-signal-bars3")]
    }
  }
}

extension UIImage {
  func applying(tintColor: UIColor) -> UIImage {
    let drawRect = CGRect(origin: .zero, size: size)
    UIGraphicsBeginImageContextWithOptions(drawRect.size, false, 0)
    guard
      let context = UIGraphicsGetCurrentContext(),
      let cgImage = self.cgImage
    else { return self }
    
    context.translateBy(x: 0, y: size.height)
    context.scaleBy(x: 1, y: -1)
    
    // draw original image
    context.setBlendMode(.normal)
    context.draw(cgImage, in: drawRect)
    
    // draw color atop
    context.setFillColor(tintColor.cgColor)
    context.setBlendMode(.sourceAtop)
    context.fill(drawRect)
    
    let tinted = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return tinted ?? self
  }
}
