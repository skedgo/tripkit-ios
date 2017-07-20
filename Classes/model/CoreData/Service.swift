//
//  Service.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension Service {
  
  public var region: SVKRegion? {
    if let visit = visits?.first {
      return visit.stop.region
    } else {
      // we might not have visits if they got deleted in the mean-time
      return nil
    }
  }
  
  public var modeTitle: String? {
    if let alt = modeInfo?.alt {
      return alt
    }
    
    if let reference = segments?.first {
      return reference.template().modeInfo.alt
    }
    
    if let visit = visits?.first {
      return visit.stop.modeTitle
    }
    
    assertionFailure("Got no mode, visits or segments!")
    return nil;
  }
  
  public func modeImage(for type: SGStyleModeIconType) -> SGKImage? {
    if let modeInfo = modeInfo, let specificImage = SGStyleManager.image(forModeImageName: modeInfo.localImageName, isRealTime: false, of: type) {
      return specificImage
    }
    
    if let visit = visits?.first {
      return visit.stop.modeImage(for: type)
    }
    
    assertionFailure("Got no mode, visits or segments!")
    return nil;
  }
  
  public func modeImageURL(for type: SGStyleModeIconType) -> URL? {
    guard let remoteImage = modeInfo?.remoteImageName else { return nil }
    return SVKServer.imageURL(forIconFileNamePart: remoteImage, of: type)
  }
  
}
