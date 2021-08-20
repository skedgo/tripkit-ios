//
//  UIColor+TripGoDefault.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 19/9/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

#if os(iOS) || os(tvOS)

import Foundation
import UIKit

extension UIColor {
  
  static let tripgoTintColor: UIColor = {
    #if targetEnvironment(macCatalyst)
    // Catalyst prefers the system accent color, which we can get like this
    let dummyButton = UIButton()
    return dummyButton.tintColor
    #else
    if #available(iOS 13.0, *) {
      return UIColor { traits in
        switch traits.userInterfaceStyle {
        case .dark: return #colorLiteral(red: 0, green: 0.8, blue: 0.4, alpha: 1)
        case _: return #colorLiteral(red: 0, green: 0.8, blue: 0.4, alpha: 1)
        }
      }
    } else { return #colorLiteral(red: 0, green: 0.8, blue: 0.4, alpha: 1) }
    #endif
  }()
  
  
  // MARK: - Buttons
  
  static let tripgoFilledButtonBackground: UIColor = .tkAppTintColor
  static let tripgoFilledButtonTextColor: UIColor  = .white
  static let tripgoEmptyButtonBackground: UIColor  = .tkBackground
  static let tripgoEmptyButtonTextColor: UIColor   = .tkLabelPrimary
  
  // MARK: - Background
  
  static let tripgoBackground          = UIColor(named: "TKBackground", in: .tripKit, compatibleWith: nil)!
  static let tripgoBackgroundSecondary = UIColor(named: "TKBackgroundSecondary", in: .tripKit, compatibleWith: nil)!
  static let tripgoBackgroundTile      = UIColor.tkBackground
  static let tripgoBackgroundBelowTile = UIColor.tkBackgroundSecondary
  static let tripgoBackgroundGrouped   = UIColor.tkBackgroundSecondary
  
  static let tripgoBackgroundSelected: UIColor = {
    if #available(iOS 13.0, *) {
      return UIColor { traits in
        switch traits.userInterfaceStyle {
        case .dark:
          return #colorLiteral(red: 0.2274509804, green: 0.2274509804, blue: 0.2352941176, alpha: 1)
        case _:
          return #colorLiteral(red: 0.8196078431, green: 0.8196078431, blue: 0.8392156863, alpha: 1)
        }
      }
    } else {
      return #colorLiteral(red: 0.8196078431, green: 0.8196078431, blue: 0.8392156863, alpha: 1)
    }
  }()
  
  // MARK: - Labels
  
  static let tripgoLabelPrimary     = UIColor(named: "TKLabelPrimary", in: .tripKit, compatibleWith: nil)!
  static let tripgoLabelSecondary   = UIColor(named: "TKLabelSecondary", in: .tripKit, compatibleWith: nil)!
  static let tripgoLabelTertiary    = UIColor(named: "TKLabelTertiary", in: .tripKit, compatibleWith: nil)!
  static let tripgoLabelQuarternary = UIColor(named: "TKLabelQuarternary", in: .tripKit, compatibleWith: nil)!
  
  // MARK: - States
    
  static let tripgoStateError   = UIColor(named: "TKStateError", in: .tripKit, compatibleWith: nil)!
  static let tripgoStateWarning = UIColor(named: "TKStateWarning", in: .tripKit, compatibleWith: nil)!
  static let tripgoStateSuccess = UIColor(named: "TKStateSuccess", in: .tripKit, compatibleWith: nil)!
  
  // MARK: - Accessories
  
  static let tripgoSeparator: UIColor = {
    if #available(iOS 13.0, *) {
      return .separator
    } else {
      return #colorLiteral(red: 0.8196078431, green: 0.8196078431, blue: 0.831372549, alpha: 1)
    }
  }()
  
  static let tripgoSeparatorSubtle: UIColor = {
    if #available(iOS 13.0, *) {
      return UIColor { traits in
        switch traits.userInterfaceStyle {
        case .dark:
          return #colorLiteral(red: 0.1000000015, green: 0.1000000015, blue: 0.1000000015, alpha: 1)
        case _:
          return #colorLiteral(red: 0.9053974748, green: 0.9053974748, blue: 0.9053974748, alpha: 1)
        }
      }
    } else {
      return #colorLiteral(red: 0.9053974748, green: 0.9053974748, blue: 0.9053974748, alpha: 1)
    }
  }()
  
  static let tripgoMapOverlay: UIColor = {
    if #available(iOS 13.0, *) {
      return UIColor { traits in
        switch (traits.userInterfaceStyle, traits.accessibilityContrast) {
        case (.dark, _):
          return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.9)
        case (_, _):
          return #colorLiteral(red: 0.2039215686, green: 0.3058823529, blue: 0.4274509804, alpha: 0.5)
        }
      }
    } else {
      return #colorLiteral(red: 0.2039215686, green: 0.3058823529, blue: 0.4274509804, alpha: 0.5)
    }
  }()
  
  static let tripgoSheetOverlay: UIColor = {
    if #available(iOS 13.0, *) {
      return UIColor { traits in
        switch (traits.userInterfaceStyle, traits.accessibilityContrast) {
        case (.dark, _):
          return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.8)
        case (_, _):
          return #colorLiteral(red: 0.2039215686, green: 0.3058823529, blue: 0.4274509804, alpha: 0.8)
        }
      }
    } else {
      return #colorLiteral(red: 0.2039215686, green: 0.3058823529, blue: 0.4274509804, alpha: 0.8)
    }
  }()
  
  static let tripgoStatusBarOverlay: UIColor = {
    if #available(iOS 13.0, *) {
      return UIColor { traits in
        switch (traits.userInterfaceStyle, traits.accessibilityContrast) {
        case (.dark, _):
          return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.8)
        case (_, _):
          return #colorLiteral(red: 0.2039215686, green: 0.3058823529, blue: 0.4274509804, alpha: 0.7)
        }
      }
    } else {
      return #colorLiteral(red: 0.2039215686, green: 0.3058823529, blue: 0.4274509804, alpha: 0.7)
    }
  }()
  
  // MARK: - Neutral
  
  private static let tripgoBlack = UIColor(red: 33/255, green: 42/255, blue: 51/255, alpha: 1)
  
  static let tripgoNeutral  = UIColor(named: "TKNeutral", in: .tripKit, compatibleWith: nil)!
  static let tripgoNeutral1 = UIColor(named: "TKNeutral1", in: .tripKit, compatibleWith: nil)!
  static let tripgoNeutral2 = UIColor(named: "TKNeutral2", in: .tripKit, compatibleWith: nil)!
  static let tripgoNeutral3 = UIColor(named: "TKNeutral3", in: .tripKit, compatibleWith: nil)!
  static let tripgoNeutral4 = UIColor(named: "TKNeutral4", in: .tripKit, compatibleWith: nil)!
  static let tripgoNeutral5 = UIColor(named: "TKNeutral5", in: .tripKit, compatibleWith: nil)!
  
}

#endif
