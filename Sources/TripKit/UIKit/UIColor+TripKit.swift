//
//  UIColor+TripKitUI.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 30.07.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

#if os(iOS) || os(tvOS)

import Foundation
import UIKit

extension UIColor {
  
  // MARK: - Primary
  
  @objc public static var tkAppTintColor: UIColor = .tripgoTintColor
  
  @objc public static var tkBarBackgroundColor: UIColor = TKStyleManager.globalBarTintColor
  
  @objc public static var tkBarForegroundColor: UIColor = TKStyleManager.globalAccentColor
  
  // MARK: - Labels
  
  @objc public static var tkLabelPrimary: UIColor = .tripgoLabelPrimary
  @objc public static var tkLabelSecondary: UIColor = .tripgoLabelSecondary
  @objc public static var tkLabelTertiary: UIColor = .tripgoLabelTertiary
  @objc public static var tkLabelQuarternary: UIColor = .tripgoLabelQuarternary
  
  @objc public static var tkLabelOnDark: UIColor = .white
  @objc public static var tkLabelOnLight: UIColor = .darkText
  
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
  
  /// The background colour for separators
  @objc public static var tkBarSecondary: UIColor = .tripgoBarSecondary
  
  // MARK: - Accessories

  @objc public static var tkSeparator: UIColor = .tripgoSeparator
  
  /// Secondary, more subtle, separator which is useful for views like table view cells  that are already
  /// separted via a separator but also need to display a separator as a subview
  @objc public static var tkSeparatorSubtle: UIColor = .tripgoSeparatorSubtle

  @objc public static var tkMapOverlay: UIColor = .tripgoMapOverlay
  @objc public static let tkSheetOverlay: UIColor = .tripgoSheetOverlay
  @objc public static let tkStatusBarOverlay: UIColor = .tripgoStatusBarOverlay
  
  // MARK: - Neutral
  
  @objc public static var tkNeutral: UIColor = .tripgoNeutral
  @objc public static var tkNeutral1: UIColor = .tripgoNeutral1
  @objc public static var tkNeutral2: UIColor = .tripgoNeutral2
  @objc public static var tkNeutral3: UIColor = .tripgoNeutral3
  @objc public static var tkNeutral4: UIColor = .tripgoNeutral4
  @objc public static var tkNeutral5: UIColor = .tripgoNeutral5
  
}

#endif
