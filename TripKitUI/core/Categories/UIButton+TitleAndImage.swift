//
//  UIButton+CenterImage.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 30/11/2016.
//
//

import Foundation

extension UIButton {
  
  // http://stackoverflow.com/questions/4564621/aligning-text-and-image-on-uibutton-with-imageedgeinsets-and-titleedgeinsets
  public func centerTextAndImage(spacing: CGFloat) {
    let insetAmount = spacing / 2
    imageEdgeInsets = UIEdgeInsets(top: 0, left: -insetAmount, bottom: 0, right: insetAmount)
    titleEdgeInsets = UIEdgeInsets(top: 8, left: insetAmount, bottom: 8, right: -insetAmount)
    contentEdgeInsets = UIEdgeInsets(top: 8, left: insetAmount, bottom: 8, right: insetAmount)
  }
  
}
