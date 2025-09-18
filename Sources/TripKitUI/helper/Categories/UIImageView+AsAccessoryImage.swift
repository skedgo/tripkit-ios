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
    
    let images = UIImageView.realTimeAccessoryImage(animated, tintColor: tintColor)
    if images.count > 1, let last = images.last {
      self.image = last
      self.animationImages = images
      self.animationDuration = 1
      self.animationRepeatCount = 3
      self.contentMode = .scaleAspectFit
      self.startAnimating()
      
    } else {
      self.image = images.first
      self.tintColor = tintColor
    }
    self.accessibilityLabel = Loc.RealTime
  }
  
  private static func realTimeAccessoryImage(_ animated: Bool, tintColor: UIColor?) -> [UIImage] {
    if animated {
     let name = "dot.radiowaves.forward"
     let image1 = UIImage(systemName: name, variableValue: 0.3)
     let image2 = UIImage(systemName: name, variableValue: 0.7)
     let image3 = UIImage(systemName: name, variableValue: 1.0)
        
     let images = [image1, image2, image3, image3, image3, image3, image3, image3]
        
      if let tintColor {
        let config = UIImage.SymbolConfiguration(hierarchicalColor: tintColor)
       
        return images
          .compactMap { $0?.applyingSymbolConfiguration(config)?.pngData() }
          .compactMap { UIImage(data: $0) }

      } else {
        return images
           .compactMap { $0 }
      }
      
    } else {
      // Right-pointing, all bars
      return [UIImage(systemName: "dot.radiowaves.forward")].compactMap { $0 }
    }
  }
}
