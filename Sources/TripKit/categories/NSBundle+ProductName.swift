//
//  NSBundle+ProductName.swift
//  TripKit
//
//  Created by Adrian Schoenig on 07.08.17.
//
//

import Foundation

extension Bundle {
  
  @objc public var productName: String? {
    
    if let localizedDict = localizedInfoDictionary {
      if let candidate = localizedDict[kCFBundleNameKey as String] as? String, !candidate.hasPrefix("$") {
        return candidate
      } else if let candidate = localizedDict["CFBundleDisplayName"] as? String, !candidate.hasPrefix("$") {
        return candidate
      }
    }

    if let infoDict = infoDictionary {
      if let candidate = infoDict[kCFBundleNameKey as String] as? String, !candidate.hasPrefix("$") {
        return candidate
      } else if let candidate = infoDict["CFBundleDisplayName"] as? String, !candidate.hasPrefix("$") {
        return candidate
      }
    }
    
    return nil
  }
  
}
