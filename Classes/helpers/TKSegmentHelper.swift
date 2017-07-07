//
//  TKSegmentHelper.swift
//  Pods
//
//  Created by Adrian Schoenig on 4/07/2016.
//
//

import Foundation

public class TKSegmentHelper: NSObject {
  public static func segmentImage(_ iconType: SGStyleModeIconType, modeInfo: ModeInfo, modeIdentifier: String?, isRealTime: Bool) -> SGKImage? {
    guard let imageName = modeInfo.localImageName else { return nil }
    return segmentImage(iconType, localImageName: imageName, modeIdentifier: modeIdentifier, isRealTime: isRealTime)
  }

  public static func segmentImage(_ iconType: SGStyleModeIconType, localImageName: String, modeIdentifier: String?, isRealTime: Bool) -> SGKImage? {
    if let specificImage = SGStyleManager.image(forModeImageName: localImageName, isRealTime: isRealTime, of: iconType) {
      return specificImage
    }

    guard let modeIdentifier = modeIdentifier else { return nil }
    let genericImageName = SVKTransportModes.modeImageName(forModeIdentifier: modeIdentifier)
    return SGStyleManager.image(forModeImageName: genericImageName, isRealTime: isRealTime, of: iconType)
  }

}
