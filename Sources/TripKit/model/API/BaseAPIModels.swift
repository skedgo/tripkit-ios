//
//  BaseAPIModels.swift
//  TripKit
//
//  Created by Adrian Schoenig on 22.09.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation
import CoreLocation
import CoreGraphics
import MapKit

extension TKAPI {
  
  public struct CompanyInfo: Codable, Hashable {
    public let name: String
    public let website: URL?
    public let phone: String?
    public let remoteIcon: String?
    public let remoteDarkIcon: String?
    public let color: RGBColor?
    public let appInfo: AppInfo?
    
    public init(name: String, website: URL? = nil, phone: String? = nil, remoteIcon: String? = nil, remoteDarkIcon: String? = nil, color: RGBColor? = nil, appInfo: AppInfo? = nil) {
      self.name = name
      self.website = website
      self.phone = phone
      self.remoteIcon = remoteIcon
      self.remoteDarkIcon = remoteDarkIcon
      self.color = color
      self.appInfo = appInfo
    }
    
    // MARK: Codable (more robust)
    
    public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      
      name = try values.decode(String.self, forKey: .name)
      website = try? values.decode(URL.self, forKey: .website)
      phone = try? values.decode(String.self, forKey: .phone)
      remoteIcon = try? values.decode(String.self, forKey: .remoteIcon)
      remoteDarkIcon = try? values.decode(String.self, forKey: .remoteDarkIcon)
      color = try? values.decode(RGBColor.self, forKey: .color)
      appInfo = try? values.decode(AppInfo.self, forKey: .appInfo)
    }
    
  }
  
  public struct DataAttribution: Codable, Hashable {
    public let provider: CompanyInfo
    public let disclaimer: String?
    
    public init(provider: CompanyInfo, disclaimer: String? = nil) {
      self.provider = provider
      self.disclaimer = disclaimer
    }
  }
  
  public struct Location: Codable, Hashable {
    let lat: CLLocationDegrees
    let lng: CLLocationDegrees
    let bearing: CLLocationDirection?
    let name: String?
    let address: String?
  }
  
  public enum RealTimeStatus: String, Codable, Equatable {
    case capable    = "CAPABLE"
    case incapable  = "INCAPABLE"
    
    case isRealTime = "IS_REAL_TIME"
    case canceled   = "CANCELLED"
  }

  public struct RGBColor: Codable, Hashable {
    let red: Int
    let green: Int
    let blue: Int
    
    public var color: TKColor {
      return TKColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: 1)
    }
    
#if canImport(UIKit)
      public init?(for color: TKColor?) {
        guard let color = color else { return nil }
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        if color.getRed(&red, green: &green, blue: &blue, alpha: nil) {
          self.red = Int(red * 255)
          self.green = Int(green * 255)
          self.blue = Int(blue * 255)
        } else {
          return nil
        }
      }
#elseif canImport(AppKit)
    public init?(for color: TKColor?) {
      guard let color = color else { return nil }
      var red: CGFloat = 0
      var green: CGFloat = 0
      var blue: CGFloat = 0
      color.getRed(&red, green: &green, blue: &blue, alpha: nil)
      self.red = Int(red * 255)
      self.green = Int(green * 255)
      self.blue = Int(blue * 255)
    }
#endif
  }
  
}


extension TKAPI.CompanyInfo {
  
  public var remoteIconURL: URL? {
    guard let fileNamePart = remoteIcon else {
      return nil
    }
    
    return TKServer.imageURL(iconFileNamePart: fileNamePart, iconType: .listMainMode)
  }
  
  public var remoteDarkIconURL: URL? {
    guard let fileNamePart = remoteDarkIcon else {
      return nil
    }
    
    return TKServer.imageURL(iconFileNamePart: fileNamePart, iconType: .listMainMode)
  }
  
}

// MARK - Helpers

extension TKAPI.Location {
  
  public init?(annotation: MKAnnotation?) {
    guard let annotation = annotation else { return nil }
    self.lat = annotation.coordinate.latitude
    self.lng = annotation.coordinate.longitude
    self.name = (annotation.title ?? nil)
    self.address = (annotation.subtitle ?? nil)
    self.bearing = nil
  }
  
}

extension TKNamedCoordinate {
  public convenience init(_ remote: TKAPI.Location) {
    self.init(latitude: remote.lat, longitude: remote.lng, name: remote.name, address: remote.address)
  }
}
