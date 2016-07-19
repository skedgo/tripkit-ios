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
  public static func segmentImage(iconType: SGStyleModeIconType, modeInfo: ModeInfo, modeIdentifier: String?, isRealTime: Bool) -> UIImage? {
    return segmentImage(iconType, localImageName: modeInfo.localImageName, modeIdentifier: modeIdentifier, isRealTime: isRealTime)
  }

  public static func segmentImage(iconType: SGStyleModeIconType, localImageName: String, modeIdentifier: String?, isRealTime: Bool) -> UIImage? {
    if let specificImage = SGStyleManager.imageForModeImageName(localImageName, isRealTime: isRealTime, ofIconType: iconType) {
      return specificImage
    }

    guard let modeIdentifier = modeIdentifier else { return nil }
    let genericImageName = SVKTransportModes.modeImageNameForModeIdentifier(modeIdentifier)
    return SGStyleManager.imageForModeImageName(genericImageName, isRealTime: isRealTime, ofIconType: iconType)
  }

}