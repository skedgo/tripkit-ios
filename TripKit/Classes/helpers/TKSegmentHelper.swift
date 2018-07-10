//
//  TKSegmentHelper.swift
//  TripKit
//
//  Created by Adrian Schoenig on 4/07/2016.
//
//

import Foundation

public class TKSegmentHelper: NSObject {
  @objc public static func segmentImage(_ iconType: TKStyleModeIconType, modeInfo: TKModeInfo, modeIdentifier: String?, isRealTime: Bool) -> TKImage? {
    guard let imageName = modeInfo.localImageName else { return nil }
    return segmentImage(iconType, localImageName: imageName, modeIdentifier: modeIdentifier, isRealTime: isRealTime)
  }

  @objc public static func segmentImage(_ iconType: TKStyleModeIconType, localImageName: String, modeIdentifier: String?, isRealTime: Bool) -> TKImage? {
    if let specificImage = TKStyleManager.image(forModeImageName: localImageName, isRealTime: isRealTime, of: iconType) {
      return specificImage
    }

    guard let modeIdentifier = modeIdentifier else { return nil }
    let genericImageName = TKTransportModes.modeImageName(forModeIdentifier: modeIdentifier)
    return TKStyleManager.image(forModeImageName: genericImageName, isRealTime: isRealTime, of: iconType)
  }

}
