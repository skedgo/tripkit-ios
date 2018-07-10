//
//  TKUISemaphoreView.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 11.12.17.
//

import Foundation

@available(*, unavailable, renamed: "TKUISemaphoreView")
public typealias SGSemaphoreView = TKUISemaphoreView

extension TKUISemaphoreView {
  
  @objc public static var customHeadTintColor: UIColor? = nil
  @objc public static var customHeadImage: UIImage? = nil
  @objc public static var customPointerImage: UIImage? = nil

  @objc
  public static var headTintColor: UIColor {
    if let custom = customHeadTintColor {
      return custom
    } else {
      return TKStyleManager.darkTextColor()
    }
  }

  
  @objc
  public static var headImage: UIImage {
    if let custom = customHeadImage {
      return custom
    } else {
      return TripKitUIBundle.imageNamed("map-pin-head")
    }
  }

  @objc
  public static var pointerImage: UIImage {
    if let custom = customPointerImage {
      return custom
    } else {
      return TripKitUIBundle.imageNamed("map-pin-pointer")
    }
  }

  
}
