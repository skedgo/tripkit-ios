//
//  Service.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension Service {
  
  @objc public var region: SVKRegion? {
    if let visit = visits?.first {
      return visit.stop.region
    } else {
      // we might not have visits if they got deleted in the mean-time
      return nil
    }
  }
  
  @objc public var modeTitle: String? {
    return findModeInfo()?.alt
  }
  
  @objc public func modeImage(for type: SGStyleModeIconType) -> SGKImage? {
    return SGStyleManager.image(forModeImageName: findModeInfo()?.localImageName, isRealTime: isRealTime, of: type)
  }
  
  @objc public func modeImageURL(for type: SGStyleModeIconType) -> URL? {
    guard let remoteImage = findModeInfo()?.remoteImageName else { return nil }
    return SVKServer.imageURL(forIconFileNamePart: remoteImage, of: type)
  }

  private func findModeInfo() -> ModeInfo? {
    if let modeInfo = modeInfo {
      return modeInfo
    }
    for visit in visits ?? [] where visit.stop.stopModeInfo != nil {
      return visit.stop.stopModeInfo
    }
    for segment in segments ?? [] where segment.segmentTemplate?.modeInfo != nil {
      return segment.segmentTemplate?.modeInfo
    }

    assertionFailure("Got no mode, visits or segments!")
    return nil
  }

}
