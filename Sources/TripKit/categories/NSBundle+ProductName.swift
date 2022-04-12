//
//  NSBundle+ProductName.swift
//  TripKit
//
//  Created by Adrian Schoenig on 07.08.17.
//
//

import Foundation

extension Bundle {
  
  /// Product name, preferring name from localized Info.plist and preferring display name over product name.
  @objc public var productName: String? {
    if let candidate = localizedInfoDictionary?["CFBundleDisplayName"] as? String, !candidate.hasPrefix("$") {
      return candidate
    } else if let candidate = localizedInfoDictionary?[kCFBundleNameKey as String] as? String, !candidate.hasPrefix("$") {
      return candidate
    } else if let candidate = infoDictionary?["CFBundleDisplayName"] as? String, !candidate.hasPrefix("$") {
      return candidate
    } else if let candidate = infoDictionary?[kCFBundleNameKey as String] as? String, !candidate.hasPrefix("$") {
      return candidate
    } else {
      return nil
    }
  }
  
}
