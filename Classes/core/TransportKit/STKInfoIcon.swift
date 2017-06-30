//
//  STKInfoIcon.swift
//  Pods
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

@objc
public enum STKInfoIconType : Int {
  case none = 0
  case alert // red icon
  case warning // yellow icon
  case unknownLocation // pin with ?
}

@objc
public enum STKInfoIconUsage : Int {
  case normal
  case overlay
  case map
}


public class STKInfoIcon : NSObject {
  
  private override init() {
  }
  
  @objc(imageNameForInfoIconType:usage:)
  public static func imageName(for type: STKInfoIconType, usage: STKInfoIconUsage) -> String? {
    
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
  public static func image(for type: STKInfoIconType, usage: STKInfoIconUsage) -> SGKImage? {
    guard
      let fileName = imageName(for: type, usage: usage)
      else { return nil }
    return SGStyleManager.imageNamed(fileName)
  }

  private static func addendum(for usage: STKInfoIconUsage) -> String {
    switch usage {
    case .map: return "-map"
    case .overlay: return "-overlay"
    case .normal: return ""
    }
  }
  
}
