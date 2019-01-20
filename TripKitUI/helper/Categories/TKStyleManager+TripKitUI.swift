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
  
  /// This method returns a semibold font with custom font face for a given text style.
  /// If there's no custom font face specified in the plist, system font face is used.
  /// This method is typically used on `UILabel`, `UITextField`, and `UITextView` but
  /// not recommended for system controls, such as `UIButton`.
  ///
  /// - Parameter textStyle: TextStyle desired
  /// - Returns: A semibold font with custom font face.
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
  
  /// This method returns a regular font with custom font face for a given text style.
  /// If there's no custom font face specified in the plist, system font face is used.
  /// This method is typically used on `UILabel`, `UITextField`, and `UITextView` but
  /// not recommended for system controls, such as `UIButton`.
  ///
  /// - Parameter textStyle: TextStyle desired
  /// - Returns: A regular font with custom font face.
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
  
  /// This method returns a bold font with custom font face for a given text style.
  /// If there's no custom font face specified in the plist, system font face is used.
  /// This method is typically used on `UILabel`, `UITextField`, and `UITextView` but
  /// not recommended for system controls, such as `UIButton`.
  ///
  /// - Parameter textStyle: TextStyle desired
  /// - Returns: A bold font with custom font face.
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
  
  /// This method returns a medium font with custom font face for a given text style.
  /// If there's no custom font face specified in the plist, system font face is used.
  /// This method is typically used on `UILabel`, `UITextField`, and `UITextView` but
  /// not recommended for system controls, such as `UIButton`.
  ///
  /// - Parameter textStyle: TextStyle desired
  /// - Returns: A semibold font with custom font face.
  @objc public static func mediumCustomFont(forTextStyle textStyle: UIFont.TextStyle) -> UIFont {
    let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)
    guard
      let preferredFontName = UIFont.preferredMediumFontName(),
      let customFont = UIFont(name: preferredFontName, size: descriptor.pointSize)
      else {
        return UIFont.systemFont(ofSize: descriptor.pointSize, weight: .medium)
    }
    
    if #available(iOS 11.0, *) {
      return UIFontMetrics.default.scaledFont(for: customFont)
    } else {
      return customFont
    }
  }
  
}

