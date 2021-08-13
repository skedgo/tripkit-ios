//
//  TKInfoIcon.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

@objc
public enum TKInfoIconType : Int {
  case none = 0
  case alert // red icon
  case warning // yellow icon
  case unknownLocation // pin with ?
}

@objc
public enum TKInfoIconUsage : Int {
  case normal
  case overlay
  case map
}


public class TKInfoIcon : NSObject {
  
  private override init() {
  }
  
  @available(*, deprecated, message: "Use `image(for:usage:) instead")
  @objc(imageNameForInfoIconType:usage:)
  public static func imageName(for type: TKInfoIconType, usage: TKInfoIconUsage) -> String? {
    return _imageName(for:type, usage:usage)
  }
  
  private static func _imageName(for type: TKInfoIconType, usage: TKInfoIconUsage) -> String? {
  
    switch type {

    case .none:
      return nil

    case .unknownLocation:
      return "icon-location-alert"

    case .alert:
      let addendum = self.addendum(for: usage)
      return "icon-alert-red\(addendum)"

    case .warning:
      let addendum = self.addendum(for: usage)
      return "icon-alert-yellow\(addendum)"
    }
    
  }

  @objc(imageForInfoIconType:usage:)
  public static func image(for type: TKInfoIconType, usage: TKInfoIconUsage) -> TKImage? {
    guard
      let fileName = _imageName(for: type, usage: usage)
      else { return nil }
    return TKStyleManager.imageNamed(fileName)
  }

  private static func addendum(for usage: TKInfoIconUsage) -> String {
    switch usage {
    case .map: return "-map"
    case .overlay: return "-overlay"
    case .normal: return ""
    }
  }
  
}
