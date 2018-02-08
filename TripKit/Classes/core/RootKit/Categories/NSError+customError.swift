//
//  NSError+customError.swift
//  TripKit
//
//  Created by Adrian Schoenig on 25/11/16.
//
//

import Foundation

extension NSError {

  @objc(errorWithCode:message:)
  public static func error(code: Int, message: String) -> NSError {
    return NSError(code: code, message: message)
  }
  
  @objc public convenience init(code: Int, message: String) {
    let dict = [
      NSLocalizedDescriptionKey: message
    ]
    let domain = (Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String) ?? "com.skedgo.shared-ios"
    self.init(domain: domain, code: code, userInfo: dict)
  }
  
}
