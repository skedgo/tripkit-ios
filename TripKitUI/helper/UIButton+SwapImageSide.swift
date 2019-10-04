//
//  UIButton+SwapImageSide.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 04.10.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

extension UIButton {
  func switchImageToOtherSide() {
    transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
    titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
    imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
  }
}
