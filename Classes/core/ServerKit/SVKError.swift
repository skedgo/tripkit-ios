//
//  SVKUserError.swift
//  TripKit
//
//  Created by Adrian Schoenig on 20/10/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

enum SVKErrorCode: Int {
  case unsupportedRegionCombination  = 1001
  case unsupportedOriginRegion       = 1002
  case unsupportedDestinationRegion  = 1003
  case destinationTooCloseToOrigin   = 1101
  case noOrigin                      = 1102
  case noDestination                 = 1103
  case timeTooOld                    = 1201
  case departureTimeTooOld           = 1202
  case arrivalTimeTooOld             = 1203
}

class SVKUserError: SVKError {
  override var isUserError: Bool {
    return true
  }
}

class SVKServerError: SVKError {
}

public struct SVKErrorRecovery: Codable {
  public enum Option: String, Codable {
    case back   = "BACK"
    case retry  = "RETRY"
    case abort  = "ABORT"
  }
  
  private enum CodingKeys: String, CodingKey {
    case title = "recoveryTitle"
    case url
    case option = "recovery"
  }
  
  public let title: String?
  public let url: URL?
  public let option: Option?
}

public class SVKError: NSError {
  @objc public var title: String?
  public var recovery: SVKErrorRecovery?
  
  @objc
  public class func error(withCode code: Int, userInfo dict: [String: Any]?) -> SVKError {
    return SVKError(domain: "com.skedgo.serverkit", code: code, userInfo: dict)
  }
  
  @objc
  public class func error(fromJSON json: Any?, statusCode: Int) -> SVKError? {
    if let dict = json as? [String: Any] {
      // If there was a response body, we used that to see if it's an error
      // returned from the API.
      return SVKError.error(fromJSON: dict, domain: "com.skedgo.serverkit")
      
    } else {
      // Otherwise we check if the status code is indicating an error
      switch statusCode {
      case 404, 500...599:
        return SVKError.error(withCode: statusCode, userInfo: nil)
      default:
        return nil
      }
    }
  }
  
  @objc
  class func error(fromJSON dictionary: [String: Any], domain: String) -> SVKError? {
    guard let errorInfo = dictionary["error"] as? String,
      let isUserError = dictionary["usererror"] as? Bool
      else {
        return nil
    }
    
    var code = Int(isUserError ? kSVKServerErrorTypeUser : kSVKErrorTypeInternal)
    if let errorCode = dictionary["errorCode"] as? Int {
      code = errorCode
    }
    
    let userInfo = [ NSLocalizedDescriptionKey: errorInfo ]
    
    let error: SVKError
    
    if isUserError {
      error = SVKUserError(domain: domain, code: code, userInfo: userInfo)
    } else {
      error = SVKServerError(domain: domain, code: code, userInfo: userInfo)
    }
    
    error.title = dictionary["title"] as? String
    error.recovery = try? JSONDecoder().decode(SVKErrorRecovery.self, withJSONObject: dictionary)
    
    return error
  }
  
  @objc
  public var isUserError: Bool {
    return false
  }
  
}

