//
//  TKModeInfo+Image.swift
//  TripKit-iOS
//
//  Created by Adrian Schönig on 21.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

#if SWIFT_PACKAGE
import TripKitObjc
#endif

extension TKModeInfo {
  
  public var image: TKImage? {
    return self.image(type: .listMainMode)
  }

  public var imageURL: URL? {
    return self.imageURL(type: .listMainMode)
  }
  
  public func image(type: TKStyleModeIconType, isRealTime: Bool = false) -> TKImage? {
    return TKStyleManager.image(forModeImageName: localImageName, isRealTime: isRealTime, of: type)
  }
  
  public func imageURL(type: TKStyleModeIconType) -> URL? {
    var iconFileNamePart: String? = nil
    
    switch type {
    case .mapIcon, .listMainMode, .resolutionIndependent:
      iconFileNamePart = remoteImageName
      
    case .vehicle, .alert:
      return nil // not supported
    @unknown default:
      return nil
    }
    
    if let part = iconFileNamePart {
      return TKServer.imageURL(iconFileNamePart: part, iconType: type)
    } else {
      return TKRegionManager.shared.imageURL(forModeIdentifier: identifier, iconType: type)
    }
  }
  
}
