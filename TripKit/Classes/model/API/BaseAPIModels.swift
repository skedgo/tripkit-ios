//
//  BaseAPIModels.swift
//  TripKit
//
//  Created by Adrian Schoenig on 22.09.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension API {
  
  public struct CompanyInfo : Codable, Equatable {
    public let name: String
    public let website: URL?
    public let phone: String?
    public let remoteIcon: String?
    public let remoteDarkIcon: String?
    public let color: RGBColor?
    
    public init(name: String, website: URL? = nil, phone: String? = nil, remoteIcon: String? = nil, remoteDarkIcon: String? = nil, color: RGBColor? = nil) {
      self.name = name
      self.website = website
      self.phone = phone
      self.remoteIcon = remoteIcon
      self.remoteDarkIcon = remoteDarkIcon
      self.color = color
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
    }

    
  }
  
  public struct DataAttribution : Codable, Equatable {
    public let provider: CompanyInfo
    public let disclaimer: String?
    
    public init(provider: CompanyInfo, disclaimer: String? = nil) {
      self.provider = provider
      self.disclaimer = disclaimer
    }
  }
  
  public struct Location: Codable, Equatable {
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

  public struct RGBColor: Codable, Equatable {
    let red: Int
    let green: Int
    let blue: Int
    
    public var color: TKColor {
      return TKColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: 1)
    }
    
    #if os(iOS) || os(tvOS)
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
    #elseif os(OSX)
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


extension API.CompanyInfo {
  
  public var remoteIconURL: URL? {
    guard let fileNamePart = remoteIcon else {
      return nil
    }
    
    return TKServer.imageURL(forIconFileNamePart: fileNamePart, of: .listMainMode)
  }
  
  public var remoteDarkIconURL: URL? {
    guard let fileNamePart = remoteDarkIcon else {
      return nil
    }
    
    return TKServer.imageURL(forIconFileNamePart: fileNamePart, of: .listMainMode)
  }
  
}

// MARK - Helpers

extension API.Location {
  
  public init?(annotation: MKAnnotation?) {
    guard let annotation = annotation else { return nil }
    self.lat = annotation.coordinate.latitude
    self.lng = annotation.coordinate.longitude
    self.name = (annotation.title ?? nil)
    self.address = (annotation.subtitle ?? nil)
    self.bearing = nil
  }
  
}
