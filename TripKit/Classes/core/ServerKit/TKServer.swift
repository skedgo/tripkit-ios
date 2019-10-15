//
//  TKServer.swift
//  TripKit
//
//  Created by Adrian Schoenig on 20/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

@available(*, unavailable, renamed: "TKServer")
public typealias SVKServer = TKServer

extension TKServer {
  
  public static let shared = TKServer.__sharedInstance()
  
  private static var _serverType: TKServerType?
  
  @objc public class var serverType: TKServerType {
    get {
      if let serverType = _serverType {
        return serverType
      } else if TKBetaHelper.isBeta() {
        _serverType = TKServerType(rawValue:  UserDefaults.shared.integer(forKey: TKDefaultsKeyServerType)) ?? .production
        return _serverType!
      } else {
        _serverType = .production
        return _serverType!
      }
    }
    set {
      // Only do work, if necessary, to not trigger unnecessary calls
      guard newValue != _serverType else { return }
      _serverType = newValue
      UserDefaults.shared.set(newValue.rawValue, forKey: TKDefaultsKeyServerType)
    }
  }
  
  @objc(imageURLForIconFileNamePart:ofIconType:)
  public static func _imageURL(forIconFileNamePart fileNamePart: String, of iconType: TKStyleModeIconType) -> URL? {
    return imageURL(iconFileNamePart: fileNamePart, iconType: iconType)
  }

  
  public static func imageURL(iconFileNamePart: String, iconType: TKStyleModeIconType? = nil) -> URL? {
    let regionsURLString: String
    switch serverType {
    case .production: regionsURLString = "https://api.tripgo.com/v1"
    case .beta: regionsURLString = "https://bigbang.buzzhives.com/satapp-beta"
    case .local: regionsURLString = TKServer.developmentServer()
    
    @unknown default:
      assertionFailure("Unknown server type: \(serverType)")
      return nil
    }
    
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
      #if os(iOS) || os(tvOS)
      scale = UIScreen.main.scale
      #elseif os(OSX)
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
