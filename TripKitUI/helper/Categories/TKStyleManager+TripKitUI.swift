//
//  TKStyleManager+TripKitUI.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 16/1/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

// MARK: - Default Styles

extension TKStyleManager {

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

// MARK: - Times

extension TKStyleManager {
  
  public enum CountdownMode {
    case now
    case upcoming
    case inPast
  }
  
  public struct Countdown {
    public let number: String
    public let unit: String
    
    public let durationText: String
    public let accessibilityLabel: String
    public let mode: CountdownMode
  }
  
  /// Determines how a countdown for a specific departure should be displayed.
  ///
  /// This is recommended to use for timetables, as it optionally allows
  /// rounding the minutes in a way that a user is less likely to get annoyed
  /// at the app as the displayed text will be overly pessimistic to get users
  /// to hurry up.
  ///
  /// - Parameters:
  ///   - minutes: Actual departure time in minutes from now
  ///   - fuzzifyMinutes: Whether the texts should be pessimistic
  /// - Returns: Structure with duration string, accessory label and mode
  public static func departure(forMinutes minutes: Int, fuzzifyMinutes: Bool = true) -> Countdown {
    let absoluteMinutes = abs(minutes)
    let effectiveMinutes = fuzzifyMinutes ? fuzzifiedMinutes(minutes) : minutes
    
    func parts(components: DateComponents) -> (String, String) {
      let formatter = DateComponentsFormatter()
      
      formatter.unitsStyle = .full
      let number = formatter.string(from: components)?.trimmingCharacters(in: .letters).trimmingCharacters(in: .whitespaces) ?? ""
      
      formatter.unitsStyle = .brief
      let letter = formatter.string(from: components)?.replacingOccurrences(of: number, with: "").trimmingCharacters(in: .whitespaces) ?? ""
      
      return (number, letter)
    }
    
    let durationString: String
    let number: String
    let unit: String
    switch effectiveMinutes {
    case 0:
      durationString = Loc.Now
      number = "0"
      unit = ""
      
    case ..<60: // less than an hour
      durationString = Date.durationString(forMinutes: effectiveMinutes)
      (number, unit) = parts(components: DateComponents(minute: effectiveMinutes))
      
    case ..<1440: // less than a day
      let hours = absoluteMinutes / 60
      durationString = Date.durationString(forHours: hours)
      (number, unit) = parts(components: DateComponents(hour: hours))

    default: // days
      let days = absoluteMinutes / 1440
      durationString = Date.durationString(forDays: days)
      (number, unit) = parts(components: DateComponents(day: days))
    }
    
    let mode: CountdownMode
    let accessibilityLabel: String
    switch effectiveMinutes {
    case 0:
      mode = .now
      accessibilityLabel = Loc.Now
    case ..<0:
      mode = .inPast
      accessibilityLabel = Loc.Ago(duration: durationString)
    default:
      mode = .upcoming
      accessibilityLabel = Loc.In(duration: durationString)
    }
    
    return Countdown(
      number: number,
      unit: unit,
      durationText: durationString,
      accessibilityLabel: accessibilityLabel,
      mode: mode
    )
  }
  
  @objc
  public static func departureString(forMinutes minutes: Int, fuzzifyMinutes: Bool) -> String {
    return departure(forMinutes: minutes, fuzzifyMinutes: fuzzifyMinutes).durationText
  }

  @objc
  public static func departureAccessibilityLabel(forMinutes minutes: Int, fuzzifyMinutes: Bool) -> String {
    return departure(forMinutes: minutes, fuzzifyMinutes: fuzzifyMinutes).accessibilityLabel
  }

  @objc
  public static func departureIsNow(forMinutes minutes: Int, fuzzifyMinutes: Bool) -> Bool {
    return departure(forMinutes: minutes, fuzzifyMinutes: fuzzifyMinutes).mode == .now
  }
  
  private static func fuzzifiedMinutes(_ minutes: Int) -> Int {
    switch minutes {
    case ..<0:
      return minutes
    case ..<2:
      return 0
    case ..<10:
      return minutes
    case ..<20:
      return (minutes / 2) * 2
    default:
      return (minutes / 5) * 5
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

