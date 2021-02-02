//
//  TKStyleManager+UIKit.swift
//  TripKit-iOS
//
//  Created by Adrian Schönig on 1/2/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit

// MARK: - Default Styles

extension TKStyleManager {
  
  @objc(addDefaultShadow:)
  public static func addDefaultShadow(to view: UIView) {
    view.layer.shadowOpacity = 0.2
    view.layer.shadowOffset = .init(width: 0, height: 0)
    view.layer.shadowRadius = 1
  }

  @objc(addDefaultOutline:)
  public static func addDefaultOutline(to view: UIView) {
    view.layer.borderColor = UIColor.tkSeparator.cgColor
    view.layer.borderWidth = 0.5
  }


  @objc(styleSearchBar:includingBackground:)
  public static func style(_ searchBar: UISearchBar, includingBackground: Bool = false) {
    style(searchBar, includingBackground: includingBackground, styler: { _ in })
  }

  @objc(styleSearchBar:includingBackground:styler:)
  public static func style(_ searchBar: UISearchBar, includingBackground: Bool, styler: (UITextField) -> Void) {
    searchBar.backgroundImage = includingBackground
      ? UIImage.backgroundNavSecondary
      : UIImage() // blank
    
    style(searchBar) { textField in
      textField.clearButtonMode = .whileEditing
      textField.font = customFont(forTextStyle: .subheadline)
      textField.textColor = .tkLabelPrimary
      textField.backgroundColor = .tkBackground
      
      styler(textField)
    }
  }
  
  @objc(styleSearchBar:styler:)
  public static func style(_ searchBar: UISearchBar, styler: (UITextField) -> Void) {
    if #available(iOS 13.0, *) {
      styler(searchBar.searchTextField)
    } else {
      
      if let textField = searchBar.subviews.compactMap( { $0 as? UITextField } ).first {
        styler(textField)
      
      } else if let textField = searchBar.subviews.first?.subviews.compactMap( { $0 as? UITextField } ).first {
        // look one-level deep
        styler(textField)

      } else {
        assertionFailure("Couldn't locate text field")
      }
    }
    
  }
  
}

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
    
    return UIFontMetrics.default.scaledFont(for: customFont)
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
    
    return UIFontMetrics.default.scaledFont(for: customFont)
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
    
    return UIFontMetrics.default.scaledFont(for: customFont)
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
    
    return UIFontMetrics.default.scaledFont(for: customFont)
  }
  
}

#endif
