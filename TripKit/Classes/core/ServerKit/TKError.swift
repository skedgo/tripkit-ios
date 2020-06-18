//
//  TKUserError.swift
//  TripKit
//
//  Created by Adrian Schoenig on 20/10/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

enum TKErrorCode: Int {
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

class TKUserError: TKError {
  override var isUserError: Bool {
    return true
  }
}

class TKServerError: TKError {
}

public struct TKErrorRecovery: Codable {
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

public class TKError: NSError {
  @objc public var title: String?
  public var recovery: TKErrorRecovery?
  
  @objc
  public class func error(withCode code: Int, userInfo dict: [String: Any]?) -> TKError {
    return TKError(domain: "com.skedgo.serverkit", code: code, userInfo: dict)
  }
  
  @objc
  public class func error(fromJSON json: Any?, statusCode: Int) -> TKError? {
    if let dict = json as? [String: Any] {
      // If there was a response body, we used that to see if it's an error
      // returned from the API.
      return TKError.error(fromJSON: dict, domain: "com.skedgo.serverkit")
      
    } else {
      // Otherwise we check if the status code is indicating an error
      switch statusCode {
      case 404, 500...599:
        return TKError.error(withCode: statusCode, userInfo: nil)
      default:
        return nil
      }
    }
  }
  
  @objc
  class func error(fromJSON dictionary: [String: Any], domain: String) -> TKError? {
    guard let errorInfo = dictionary["error"] as? String,
      let isUserError = dictionary["usererror"] as? Bool
      else {
        return nil
    }
    
    var code = Int(isUserError ? kTKServerErrorTypeUser : kTKErrorTypeInternal)
    if let errorCode = dictionary["errorCode"] as? Int {
      code = errorCode
    }
    
    let userInfo = [ NSLocalizedDescriptionKey: errorInfo ]
    
    let error: TKError
    
    if isUserError {
      error = TKUserError(domain: domain, code: code, userInfo: userInfo)
    } else {
      error = TKServerError(domain: domain, code: code, userInfo: userInfo)
    }
    
    error.title = dictionary["title"] as? String
    error.recovery = try? JSONDecoder().decode(TKErrorRecovery.self, withJSONObject: dictionary)
    
    return error
  }
  
  @objc
  public var isUserError: Bool {
    return code >= 400 && code < 500
  }
  
}

