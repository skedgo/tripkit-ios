//
//  UIColor+TripGoDefault.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 19/9/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension UIColor {
  
  static let tripgoTintColor: UIColor = {
    if #available(iOS 13.0, *) {
      return UIColor { traits in
        switch traits.userInterfaceStyle {
        case .dark: return #colorLiteral(red: 0, green: 0.8, blue: 0.4, alpha: 1)
        case _: return #colorLiteral(red: 0, green: 0.8, blue: 0.4, alpha: 1)
        }
      }
    } else { return #colorLiteral(red: 0, green: 0.8, blue: 0.4, alpha: 1) }
  }()
  
  
  // MARK: - Buttons
  
  static let tripgoFilledButtonBackground: UIColor = .tkAppTintColor
  static let tripgoFilledButtonTextColor: UIColor = .white
  static let tripgoEmptyButtonBackground: UIColor = .tkBackground
  static let tripgoEmptyButtonTextColor: UIColor = .tkLabelPrimary
  
  // MARK: - Background
  
  static let tripgoBackground: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKBackground", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .white
    }
  }()
  
  static let tripgoBackgroundSecondary: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKBackgroundSecondary", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return #colorLiteral(red: 0.9647058824, green: 0.9647058824, blue: 0.9647058824, alpha: 1)
    }
  }()
  
  static let tripgoBackgroundTile: UIColor = {
    if #available(iOS 11.0, *) {
      return .tkBackground
    } else {
      return #colorLiteral(red: 0.9647058824, green: 0.9647058824, blue: 0.9647058824, alpha: 1)
    }
  }()
  
  static let tripgoBackgroundBelowTile: UIColor = {
    if #available(iOS 11.0, *) {
      return .tkBackgroundSecondary
    } else {
      return #colorLiteral(red: 0.9647058824, green: 0.9647058824, blue: 0.9647058824, alpha: 1)
    }
  }()
  
  static let tripgoBackgroundGrouped: UIColor = {
    if #available(iOS 11.0, *) {
      return .tkBackgroundSecondary
    } else {
      return #colorLiteral(red: 0.9647058824, green: 0.9647058824, blue: 0.9647058824, alpha: 1)
    }
  }()
  
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
  
  static let tripgoLabelPrimary: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKLabelPrimary", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .darkText
    }
  }()
  
  static let tripgoLabelSecondary: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKLabelSecondary", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .darkText
    }
  }()
  
  static let tripgoLabelTertiary: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKLabelTertiary", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .darkText
    }
  }()
  
  static let tripgoLabelQuarternary: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKLabelQuarternary", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .darkText
    }
  }()
  
  // MARK: - States
    
  static let tripgoStateError: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKStateError", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .red
    }
  }()
  
  static let tripgoStateWarning: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKStateWarning", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .orange
    }
  }()
  
  static let tripgoStateSuccess: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKStateSuccess", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .green
    }
  }()
  
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
  
}
