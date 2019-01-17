//
//  TKStyleManager+TripKitUI.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 16/1/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

// MARK: - Font

extension TKStyleManager {
  
  @objc public static func semiboldCustomFont(forTextStyle textStyle: UIFont.TextStyle) -> UIFont {
    let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)
    guard
      let preferredFontName = UIFont.preferredSemiboldFontName(),
      let customFont = UIFont(name: preferredFontName, size: descriptor.pointSize)
      else {
        return UIFont.systemFont(ofSize: descriptor.pointSize, weight: .semibold)
    }
    
    if #available(iOS 11.0, *) {
      return UIFontMetrics.default.scaledFont(for: customFont)
    } else {
      return customFont
    }
  }
  
  @objc public static func customFont(forTextStyle textStyle: UIFont.TextStyle) -> UIFont {
    let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)
    guard
      let preferredFontName = UIFont.preferredFontName(),
      let customFont = UIFont(name: preferredFontName, size: descriptor.pointSize)
      else {
        return UIFont.systemFont(ofSize: descriptor.pointSize, weight: .regular)
    }
    
    if #available(iOS 11.0, *) {
      return UIFontMetrics.default.scaledFont(for: customFont)
    } else {
      return customFont
    }
  }
  
  @objc public static func boldCustomFont(forTextStyle textStyle: UIFont.TextStyle) -> UIFont {
    let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)
    guard
      let preferredFontName = UIFont.preferredBoldFontName(),
      let customFont = UIFont(name: preferredFontName, size: descriptor.pointSize)
      else {
        return UIFont.systemFont(ofSize: descriptor.pointSize, weight: .bold)
    }
    
    if #available(iOS 11.0, *) {
      return UIFontMetrics.default.scaledFont(for: customFont)
    } else {
      return customFont
    }
  }
  
}

