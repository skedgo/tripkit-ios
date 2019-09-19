//
//  UIColor+TripKitUI.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 30.07.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension UIColor {
  
  // MARK: - Primary
  
  @objc public static var tkAppTintColor: UIColor = .tripgoTintColor
  
  // MARK: - Labels
  
  @objc public static var tkLabelPrimary: UIColor = .tripgoLabelPrimary
  @objc public static var tkLabelSecondary: UIColor = .tripgoLabelSecondary
  @objc public static var tkLabelTertiary: UIColor = .tripgoLabelTertiary
  @objc public static var tkLabelQuarternary: UIColor = .tripgoLabelQuarternary
  
  // MARK: - Buttons
  
  @objc public static var tkFilledButtonBackgroundColor: UIColor = .tripgoFilledButtonBackground
  @objc public static var tkFilledButtonTextColor: UIColor = .tripgoFilledButtonTextColor
  @objc public static var tkEmptyButtonBackgroundColor: UIColor = .tripgoEmptyButtonBackground
  @objc public static var tkEmptyButtonTextColor: UIColor = .tripgoEmptyButtonTextColor
  
  // MARK: - States

  @objc public static var tkStateError: UIColor = .tripgoStateError
  @objc public static var tkStateWarning: UIColor = .tripgoStateWarning
  @objc public static var tkStateSuccess: UIColor = .tripgoStateSuccess
  
  // MARK: - Background
  
  /// Primary background colour
  @objc public static var tkBackground: UIColor = .tripgoBackground
  
  /// Background colour for elements that should be offset, e.g., grouped cells
  @objc public static var tkBackgroundSecondary: UIColor = .tripgoBackgroundSecondary

  /// Background colour for cells when tapping them
  @objc public static var tkBackgroundSelected: UIColor = .tripgoBackgroundSelected

  /// The background colour for tiles
  @objc public static var tkBackgroundTile: UIColor = .tripgoBackgroundTile

  /// The background colour for what's *behind* tiles
  @objc public static var tkBackgroundBelowTile: UIColor = .tripgoBackgroundBelowTile

  /// The background colour for grouped table views, where each cell would use `.tkBackground`
  /// as its background colour.
  @objc public static var tkBackgroundGrouped: UIColor = .tripgoBackgroundGrouped
  
  // MARK: - Accessories

  @objc
  public static let tkSeparator: UIColor = {
    if #available(iOS 13.0, *) {
      return .separator
    } else {
      return #colorLiteral(red: 0.8196078431, green: 0.8196078431, blue: 0.831372549, alpha: 1)
    }
  }()
  
  /// Secondary, more subtle, separator which is useful for views like table view cells  that are already
  /// separted via a separator but also need to display a separator as a subview
  @objc
  public static let tkSeparatorSubtle: UIColor = {
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


  @objc
  public static let tkMapOverlay: UIColor = {
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
  
  @objc
  public static let tkSheetOverlay: UIColor = {
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

  @objc
  public static let tkStatusBarOverlay: UIColor = {
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

// MARK: - TripGo defaults

extension UIColor {
  
  #warning("All colors defined in this extension should ideally use brand-neutral values")
  
  private static let tripgoTintColor: UIColor = {
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
  
  private static let tripgoFilledButtonBackground: UIColor = .tkAppTintColor
  private static let tripgoFilledButtonTextColor: UIColor = .white
  private static let tripgoEmptyButtonBackground: UIColor = .tkBackground
  private static let tripgoEmptyButtonTextColor: UIColor = .tkLabelPrimary
  
  // MARK: - Background
  
  private static let tripgoBackground: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKBackground", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .white
    }
  }()
  
  private static let tripgoBackgroundSecondary: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKBackgroundSecondary", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return #colorLiteral(red: 0.9647058824, green: 0.9647058824, blue: 0.9647058824, alpha: 1)
    }
  }()
  
  private static let tripgoBackgroundTile: UIColor = {
    if #available(iOS 11.0, *) {
      return .tkBackground
    } else {
      return #colorLiteral(red: 0.9647058824, green: 0.9647058824, blue: 0.9647058824, alpha: 1)
    }
  }()
  
  private static let tripgoBackgroundBelowTile: UIColor = {
    if #available(iOS 11.0, *) {
      return .tkBackgroundSecondary
    } else {
      return #colorLiteral(red: 0.9647058824, green: 0.9647058824, blue: 0.9647058824, alpha: 1)
    }
  }()
  
  private static let tripgoBackgroundGrouped: UIColor = {
    if #available(iOS 11.0, *) {
      return .tkBackgroundSecondary
    } else {
      return #colorLiteral(red: 0.9647058824, green: 0.9647058824, blue: 0.9647058824, alpha: 1)
    }
  }()
  
  private static let tripgoBackgroundSelected: UIColor = {
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
  
  private static let tripgoLabelPrimary: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKLabelPrimary", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .darkText
    }
  }()
  
  private static let tripgoLabelSecondary: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKLabelSecondary", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .darkText
    }
  }()
  
  private static let tripgoLabelTertiary: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKLabelTertiary", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .darkText
    }
  }()
  
  private static let tripgoLabelQuarternary: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKLabelQuarternary", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .darkText
    }
  }()
  
  // MARK: - States
    
  private static let tripgoStateError: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKStateError", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .red
    }
  }()
  
  private static let tripgoStateWarning: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKStateWarning", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .orange
    }
  }()
  
  private static let tripgoStateSuccess: UIColor = {
    if #available(iOS 11.0, *) {
      return UIColor(named: "TKStateSuccess", in: .tripKitUI, compatibleWith: nil)!
    } else {
      return .green
    }
  }()
  
}
