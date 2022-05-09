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