//
//  TKStyleManager.swift
//  TripKit
//
//  Created by Adrian Schoenig on 4/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension TKColor {
  
  @objc public static var routeDashColorNonTravelled: TKColor {
#if os(iOS) || os(tvOS)
    if #available(iOS 13.0, *) {
      return .secondarySystemFill
    } else {
      return TKColor.lightGray.withAlphaComponent(0.25)
    }
#elseif os(OSX)
    return TKColor.lightGray.withAlphaComponent(0.25)
#endif
  }
  
}

// MARK: - Colors

extension TKStyleManager {
  
  private static func color(for dict: [AnyHashable: Any]?) -> TKColor? {
    guard
      let red = dict?["Red"] as? NSNumber,
      let green = dict?["Green"] as? NSNumber,
      let blue = dict?["Blue"] as? NSNumber
    else { return nil }
    return TKColor(red: red.doubleValue / 255, green: green.doubleValue / 255, blue: blue.doubleValue / 255, alpha: 1)
  }
  
  public static var globalTintColor: TKColor = {
    color(for: TKConfig.shared.globalTintColor()) ?? #colorLiteral(red: 0, green: 0.8, blue: 0.4, alpha: 1)
  }()
  
  @available(*, deprecated, message: "Use dynamic colors that are compatible with Dark Mode, e.g., from TripKitUI")
  public static var globalBarTintColor: TKColor = {
    color(for: TKConfig.shared.globalBarTintColor()) ?? #colorLiteral(red: 0.1647058824, green: 0.2274509804, blue: 0.3019607843, alpha: 1)
  }()
  
  @available(*, deprecated, message: "Use dynamic colors that are compatible with Dark Mode, e.g., from TripKitUI")
  public static var globalSecondaryBarTintColor: TKColor = {
    color(for: TKConfig.shared.globalSecondaryBarTintColor()) ?? #colorLiteral(red: 0.1176470588, green: 0.1647058824, blue: 0.2117647059, alpha: 1)
  }()
  
  public static var globalAccentColor: TKColor = {
    color(for: TKConfig.shared.globalAccentColor()) ?? globalTintColor
  }()
  
}

// MARK: - Images

extension TKStyleManager {
  
  private static let dummyImage = TKImage()
  private static let imageCache = NSCache<NSString, TKImage>()
  
  public static func activityImage(_ partial: String) -> TKImage {
    let name: String
#if os(iOS) || os(tvOS)
    switch UIDevice.current.userInterfaceIdiom {
    case .phone: name = "icon-actionBar-\(partial)-30"
    default: name = "icon-actionBar-\(partial)-38"
    }
#elseif os(OSX)
    name = "icon-actionBar-\(partial)-38"
#endif
    return image(named: name)
  }
  
  public static func image(named: String) -> TKImage {
    let image = optionalImage(named: named)
    assert(image != nil, "Image named '\(named)' not found in \(TripKit.bundle).")
    return image!
  }
  
  public static func optionalImage(named: String) -> TKImage? {
#if os(iOS) || os(tvOS)
    return TKImage(named: named, in: .tripKit, compatibleWith: nil)
#elseif os(OSX)
    return TripKit.bundle.image(forResource: named)
#endif
  }
  
  public static func image(forModeImageName imageName: String?, isRealTime: Bool = false, of iconType: TKStyleModeIconType = .listMainMode) -> TKImage? {
    guard let partName = imageName?.lowercased() else {
      return nil
    }
    let key = "\(partName)-\(isRealTime)-\(iconType.rawValue)" as NSString
    if let cached = imageCache.object(forKey: key) {
      return cached == dummyImage ? nil : cached
    }
    
    let fullName: String
    switch iconType {
    case .resolutionIndependent, .vehicle, .mapIcon:
      assertionFailure("Not supported locally")
      return nil
    case .listMainMode:
      fullName = isRealTime ? "icon-mode-\(partName)-realtime" : "icon-mode-\(partName)"
    case .alert:
      fullName = "icon-alert-yellow-map"
    @unknown default:
      return nil
    }
    if let image = optionalImage(named: fullName) {
      imageCache.setObject(image, forKey: key)
      return image
    } else if isRealTime {
      return self.image(forModeImageName:imageName, isRealTime:false, of:iconType)
    } else {
      imageCache.setObject(dummyImage, forKey: key)
      return nil
    }
    
  }
  
}

// MARK: - Fonts

extension TKStyleManager {
  
  public enum FontWeight {
    case regular
    case medium
    case bold
    case semibold
    
    var weight: TKFont.Weight {
      switch self {
      case .regular: return .regular
      case .medium: return .medium
      case .bold: return .bold
      case .semibold: return .semibold
      }
    }
    
    var preferredFontName: String? {
      switch self {
      case .regular:
        return TKConfig.shared.preferredFonts()?["Regular"] as? String
      case .medium:
        return TKConfig.shared.preferredFonts()?["Medium"] as? String
      case .bold:
        return TKConfig.shared.preferredFonts()?["Bold"] as? String
      case .semibold:
        return TKConfig.shared.preferredFonts()?["Semibold"] as? String
      }
    }
  }
  
  /// This method returns a font with custom font face for a given font size and weight.
  /// If there's no custom font face specified in the plist, system font face is used.
  /// This method is recommended to use with system controls such as `UIButton`
  ///
  /// - Parameter size: Font size desired
  /// - Parameter weight: Font weight desired
  /// - Returns: A font with custom font face of the requested weight.
  public static func font(size: Double, weight: FontWeight = .regular) -> TKFont {
    if let preferredFontName = weight.preferredFontName, let font = TKFont(name: preferredFontName, size: size) {
      return font
    } else {
      return TKFont.systemFont(ofSize: size, weight: weight.weight)
    }
  }
  
#if os(iOS) || os(tvOS)
  //// This method returns a font with custom font face for a given text style and weight.
  /// If there's no custom font face specified in the plist, system font face is used.
  /// This method is typically used on `UILabel`, `UITextField`, and `UITextView` but
  /// not recommended for system controls, such as `UIButton`.
  ///
  /// - Parameter textStyle: TextStyle desired
  /// - Parameter weight: Font weight desired
  /// - Returns: A font with custom font face and weight.
  public static func font(textStyle: TKFont.TextStyle, weight: FontWeight = .regular) -> UIFont {
    let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)
    if let preferredFontName = weight.preferredFontName, let font = UIFont(name: preferredFontName, size: descriptor.pointSize) {
      return UIFontMetrics.default.scaledFont(for: font)
    } else {
      return UIFont.systemFont(ofSize: descriptor.pointSize, weight: weight.weight)
    }
  }
#endif
  
  // @available(*, deprecated, renamed: "font(size:weight:)")
  public static func systemFont(size: Double) -> TKFont {
    return font(size: size, weight: .regular)
  }

  // @available(*, deprecated, renamed: "font(size:weight:)")
  public static func boldSystemFont(size: Double) -> TKFont {
    return font(size: size, weight: .bold)
  }

  // @available(*, deprecated, renamed: "font(size:weight:)")
  public static func semiboldSystemFont(size: Double) -> TKFont {
    return font(size: size, weight: .semibold)
  }

  // @available(*, deprecated, renamed: "font(size:weight:)")
  public static func mediumSystemFont(size: Double) -> TKFont {
    return font(size: size, weight: .medium)
  }

#if os(iOS) || os(tvOS)
  // @available(*, deprecated, renamed: "font(textStyle:weight:)")
  public static func customFont(forTextStyle textStyle: UIFont.TextStyle) -> UIFont {
    return font(textStyle: textStyle, weight: .regular)
  }

  // @available(*, deprecated, renamed: "font(textStyle:weight:)")
  public static func boldCustomFont(forTextStyle textStyle: UIFont.TextStyle) -> UIFont {
    return font(textStyle: textStyle, weight: .bold)
  }

  // @available(*, deprecated, renamed: "font(textStyle:weight:)")
  public static func semiboldCustomFont(forTextStyle textStyle: UIFont.TextStyle) -> UIFont {
    return font(textStyle: textStyle, weight: .semibold)
  }

  // @available(*, deprecated, renamed: "font(textStyle:weight:)")
  public static func mediumCustomFont(forTextStyle textStyle: UIFont.TextStyle) -> UIFont {
    return font(textStyle: textStyle, weight: .medium)
  }
  #endif

}

// MARK: - Formatting

extension TKStyleManager {
  
  private static var exerciseFormatter: EnergyFormatter = {
    let formatter = EnergyFormatter()
    formatter.isForFoodEnergyUse = false // For exercise
    formatter.numberFormatter.maximumSignificantDigits = 2
    formatter.numberFormatter.usesSignificantDigits = true
    return formatter
  }()
  
  @objc(exerciseStringForCalories:)
  public static func exerciseString(calories: Double) -> String {
    return exerciseFormatter.string(fromValue: calories, unit: .kilocalorie)
  }
  
}
