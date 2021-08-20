//
//  UIColor+Variations.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 11/5/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
  var rgba: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    if getRed(&r, green: &g, blue: &b, alpha: &a) {
      return (r, g, b, a)
    } else if let components = cgColor.components, components.count == 2 {
      return (components[0], components[0], components[0], components[1])
    } else {
      assertionFailure("Couldn't get colour")
      return (r, g, b, a)
    }
  }
  
  func darkerColor(percentage: CGFloat) -> UIColor {
    let multiplier = 1 - percentage
    let rgba = self.rgba
    return UIColor(red: multiplier * rgba.r,
                   green: multiplier * rgba.g,
                   blue: multiplier * rgba.b,
                   alpha: rgba.a)
  }
  
  public var isDark: Bool {
    let rgba = self.rgba
    return (rgba.r + rgba.g + rgba.b) * rgba.a <= 1.75 // mid-range colours are dark, too
  }
}
