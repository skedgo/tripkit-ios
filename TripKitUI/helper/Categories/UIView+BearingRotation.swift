//
//  UIView+BearingRotation.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 11/5/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

extension UIView {
  func update(magneticHeading: CGFloat, bearing: CGFloat) {
    rotate(bearing: bearing - magneticHeading)
  }
  
  func rotate(bearing: CGFloat) {
    let rotation = Self.rotating(from: bearing)
    transform = CGAffineTransform(rotationAngle: rotation)
  }
  
  private static func rotating(from bearing: CGFloat) -> CGFloat {
    // 0 = North, 90 = East, 180 = South and 270 = West
    let start: CGFloat = 90
    let rotation = -1 * (start - bearing)
    return (rotation * CGFloat.pi) / 180
  }
}
