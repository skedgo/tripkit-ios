//
//  TKServer+ModeImage.swift
//  TripKit
//
//  Created by Adrian Schönig on 17/10/2022.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension TKServer {
  
  public static func imageURL(iconFileNamePart: String?, iconType: TKStyleModeIconType? = nil) -> URL? {
    guard let iconFileNamePart = iconFileNamePart else { return nil }
    let regionsURLString = TKServer.customBaseURL ?? "https://api.tripgo.com/v1"
    
    let isPNG: Bool
    let fileNamePrefix: String
    if let iconType = iconType {
      switch iconType {
      case .mapIcon:
        fileNamePrefix = "icon-map-info-"
        isPNG = true
        
      case .listMainMode:
        fileNamePrefix = "icon-mode-"
        isPNG = true
        
      case .resolutionIndependent:
        fileNamePrefix = "icon-mode-"
        isPNG = false
        
      case .vehicle:
        fileNamePrefix = "icon-vehicle-"
        isPNG = true
        
      case .alert:
        fileNamePrefix = "icon-alert-"
        isPNG = true
        
      @unknown default:
        assertionFailure("Unknown icon type: \(iconType)")
        return nil
      }

    } else {
      fileNamePrefix = ""
      isPNG = true
    }

    
    var fileNamePart = iconFileNamePart
    let fileExtension = isPNG ? "png" : "svg"
    if isPNG {
      let scale: CGFloat
#if canImport(UIKit)
      scale = UIScreen.main.scale
#elseif canImport(AppKit)
      scale = NSScreen.main?.backingScaleFactor ?? 1
#endif
      
      if scale >= 2.9 {
        fileNamePart.append("@3x")
      } else if scale >= 1.9 {
        fileNamePart.append("@2x")
      }
    }
    
    var urlString = regionsURLString
    urlString.append("/modeicons/")
    urlString.append(fileNamePrefix)
    urlString.append(fileNamePart)
    urlString.append(".")
    urlString.append(fileExtension)
    return URL(string: urlString)
  }
  
}
