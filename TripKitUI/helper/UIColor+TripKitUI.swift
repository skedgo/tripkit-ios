//
//  UIColor+TripKitUI.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 30.07.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension UIColor {
  
  @objc
  public static let tkLabelPrimary: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKLabelPrimary", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .darkText
    }
  }()
  
  @objc
  public static let tkLabelSecondary: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKLabelSecondary", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .darkText
    }
  }()
  
  @objc
  public static let tkLabelTertiary: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKLabelTertiary", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .darkText
    }
  }()
  
  @objc
  public static let tkLabelQuarternary: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKLabelQuarternary", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .darkText
    }
  }()
  

  @objc
  public static let tkStateError: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKStateError", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .red
    }
  }()
  
  @objc
  public static let tkStateWarning: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKStateWarning", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .orange
    }
  }()
  
  @objc
  public static let tkStateSuccess: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKStateSuccess", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .green
    }
  }()
  
  @objc
  public static let tkBackground: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKBackground", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .white
    }
  }()
  
  @objc
  public static let tkBackgroundSecondary: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKBackgroundSecondary", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return #colorLiteral(red: 0.9647058824, green: 0.9647058824, blue: 0.9647058824, alpha: 1)
    }
  }()

  
  @objc
  public static let tkSeparator: UIColor = {
    if #available(iOS 13.0, *) {
      return .separator
    } else {
      return #colorLiteral(red: 0.8196078431, green: 0.8196078431, blue: 0.831372549, alpha: 1)
    }
  }()

  
}
