//
//  UIColor+TripKitUI.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 30.07.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension UIColor {
  
  public static let tkLabelPrimary: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKLabelPrimary", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .darkText
    }
  }()
  
  public static let tkLabelSecondary: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKLabelSecondary", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .darkText
    }
  }()
  
  public static let tkLabelTertiary: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKLabelTertiary", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .darkText
    }
  }()
  
  public static let tkLabelQuarternary: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKLabelQuarternary", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .darkText
    }
  }()
  

  public static let tkStateError: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKStateError", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .red
    }
  }()
  
  public static let tkStateWarning: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKStateWarning", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .orange
    }
  }()
  
  public static let tkStateSuccess: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKStateSuccess", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .green
    }
  }()
  

  public static let tkBackground: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKBackground", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .white
    }
  }()
  
}
