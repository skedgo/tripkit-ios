//
//  TKSegmentHelper.swift
//  Pods
//
//  Created by Adrian Schoenig on 4/07/2016.
//
//

import Foundation
import UIKit

import SGCoreKit


public class TKSegmentHelper: NSObject {
  public static func segmentImage(_ iconType: SGStyleModeIconType, modeInfo: ModeInfo, modeIdentifier: String?, isRealTime: Bool) -> UIImage? {
    return segmentImage(iconType, localImageName: modeInfo.localImageName, modeIdentifier: modeIdentifier, isRealTime: isRealTime)
  }

  public static func segmentImage(_ iconType: SGStyleModeIconType, localImageName: String, modeIdentifier: String?, isRealTime: Bool) -> UIImage? {
    if let specificImage = SGStyleManager.image(forModeImageName: localImageName, isRealTime: isRealTime, of: iconType) {
      return specificImage
    }

    guard let modeIdentifier = modeIdentifier else { return nil }
    let genericImageName = SVKTransportModes.modeImageName(forModeIdentifier: modeIdentifier)
    return SGStyleManager.image(forModeImageName: genericImageName, isRealTime: isRealTime, of: iconType)
  }

}
