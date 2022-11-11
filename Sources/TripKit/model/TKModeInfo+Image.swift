//
//  TKModeInfo+Image.swift
//  TripKit-iOS
//
//  Created by Adrian Schönig on 21.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

@objc
public enum TKStyleModeIconType: Int {
  case listMainMode
  case mapIcon
  
  /// SVGs! You probably need SVGKit to handle these.
  case resolutionIndependent
  
  case vehicle
  
  case alert
}

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
    }
    
    if let part = iconFileNamePart {
      return TKServer.imageURL(iconFileNamePart: part, iconType: type)
    } else {
      return TKRegionManager.shared.imageURL(forModeIdentifier: identifier, iconType: type)
    }
  }
  
}
