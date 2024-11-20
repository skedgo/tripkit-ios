//
//  NSError+customError.swift
//  TripKit
//
//  Created by Adrian Schoenig on 25/11/16.
//
//

import Foundation

extension NSError {

  public static func error(code: Int, message: String) -> NSError {
    return NSError(code: code, message: message)
  }
  
  public convenience init(code: Int, message: String) {
    let dict = [
      NSLocalizedDescriptionKey: message
    ]
    let domain = (Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String) ?? "com.skedgo.tripkit-ios"
    self.init(domain: domain, code: code, userInfo: dict)
  }
  
}
