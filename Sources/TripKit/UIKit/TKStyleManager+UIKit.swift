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


  public static func style(_ searchBar: UISearchBar, includingBackground: Bool = false) {
    style(searchBar, includingBackground: includingBackground, styler: { _ in })
  }

  public static func style(_ searchBar: UISearchBar, includingBackground: Bool, styler: (UITextField) -> Void) {
    searchBar.backgroundImage = includingBackground
      ? UIImage.backgroundNavSecondary
      : UIImage() // blank
    
    let textField = searchBar.searchTextField
    textField.clearButtonMode = .whileEditing
    textField.font = customFont(forTextStyle: .subheadline)
    textField.textColor = .tkLabelPrimary
    textField.backgroundColor = .tkBackground
    styler(textField)
  }
  
}

#endif
