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

#endif
