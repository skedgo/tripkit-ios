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
  
  @objc(imageURLForIconFileNamePart:ofIconType:)
  public static func _imageURL(forIconFileNamePart fileNamePart: String, of iconType: TKStyleModeIconType) -> URL? {
    return imageURL(iconFileNamePart: fileNamePart, iconType: iconType)
  }

  
  public static func imageURL(iconFileNamePart: String, iconType: TKStyleModeIconType? = nil) -> URL? {
    let regionsURLString = TKServer.developmentServer() ?? "https://api.tripgo.com/v1"
    
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

public extension TKServer {

  enum HTTPMethod: String {
    case POST = "POST"
    case GET = "GET"
    case DELETE = "DELETE"
    case PUT = "PUT"
  }

  enum RepeatHandler {
    case repeatIn(TimeInterval)
    case repeatWithNewParameters(TimeInterval, [String: Any])
  }

  static func buildRequest(
    _ method: TKServer.HTTPMethod,
    path: String,
    parameters: [String: Any] = [:],
    region: TKRegion? = nil
  ) -> URLRequest {
    return shared.buildSkedGoRequest(withMethod: method.rawValue, path: path, parameters: parameters, region: region)
  }
}
