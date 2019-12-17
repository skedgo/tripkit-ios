//
//  SGStyleManager.swift
//  TripKit
//
//  Created by Adrian Schoenig on 4/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension SGKColor {
  
  @objc public static var routeDashColorNonTravelled: SGKColor {
    return SGKColor.lightGray.withAlphaComponent(0.25)
  }
  
}

// MARK: - Images

extension SGStyleManager {
  
  private static let dummyImage = SGKImage()
  private static let imageCache = NSCache<NSString, SGKImage>()

  
  @objc(imageForModeImageName:isRealTime:ofIconType:)
  public static func image(forModeImageName imageName: String?, isRealTime: Bool, of iconType: SGStyleModeIconType) -> SGKImage? {
    guard let partName = imageName?.lowercased() else {
      return nil
    }
    let key = "\(partName)-\(isRealTime)-\(iconType.rawValue)" as NSString
    if let cached = imageCache.object(forKey: key) {
      return key == dummyImage ? nil : cached
    }
    
    var realTime = isRealTime
    let fullName: String
    switch iconType {
    case .resolutionIndependent, .listMainModeOnDark, .resolutionIndependentOnDark, .vehicle:
      return nil // not supported locally
    case .listMainMode:
      fullName = realTime ? "icon-mode-\(partName)-realtime" : "icon-mode-\(partName)"
    case .mapIcon:
      realTime = false
      fullName = "icon-map-info-\(partName)"
    case .alert:
      fullName = "icon-alert-yellow-map"
    @unknown default:
      return nil
    }
    if let image = optionalImageNamed(fullName) {
      imageCache.setObject(image, forKey: key)
      return image
    } else if realTime {
      return self.image(forModeImageName:imageName, isRealTime:false, of:iconType)
    } else {
      imageCache.setObject(dummyImage, forKey: key)
      return nil
    }
    
  }
  
}


// MARK: - Formatting

extension SGStyleManager {

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
