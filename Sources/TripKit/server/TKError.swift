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
  
  case userError                     = 30051
  case internalError                 = 30052
}

class TKUserError: TKError {
  override var isUserError: Bool {
    return true
  }
}

class TKServerError: TKError {
}

public class TKError: NSError {
  @objc public var title: String?
  public var details: TKAPI.ServerError?
  
  @objc
  public class func error(withCode code: Int, userInfo dict: [String: Any]?) -> TKError {
    return TKError(domain: "com.skedgo.serverkit", code: code, userInfo: dict)
  }
  
  public class func error(from data: Data?, statusCode: Int) -> TKError? {
    if let data = data {
      // If there was a response body, we used that to see if it's an error
      // returned from the API.
      return TKError.error(from: data, domain: "com.skedgo.serverkit")
      
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
  
  class func error(from data: Data, domain: String) -> TKError? {
    guard let parsed = try? JSONDecoder().decode(TKAPI.ServerError.self, from: data) else { return nil }
    
    var code = Int(parsed.isUserError ? TKErrorCode.userError.rawValue : TKErrorCode.internalError.rawValue)
    if let errorCode = parsed.errorCode {
      code = errorCode
    }
    
    let userInfo: [String: Any] = [
      NSLocalizedDescriptionKey: parsed.errorMessage ?? parsed.title ?? Loc.ServerError,
      "TKIsUserError": parsed.isUserError
    ]
    
    let error: TKError
    if parsed.isUserError {
      error = TKUserError(domain: domain, code: code, userInfo: userInfo)
    } else {
      error = TKServerError(domain: domain, code: code, userInfo: userInfo)
    }
    error.title = parsed.title
    error.details = parsed
    return error
  }
  
  @objc
  public var isUserError: Bool {
    if let userError = userInfo["TKIsUserError"] as? Bool {
      return userError
    } else {
      return code >= 400 && code < 500
    }
  }
  
}

extension TKAPI {
  public struct ServerError: Codable {
    public let errorMessage: String?
    public let isUserError: Bool
    public let errorCode: Int?
    public let title: String?
    public let recovery: String?
    public let url: URL?
    public let option: Option?
    
    public enum Option: String, Codable {
      case back   = "BACK"
      case retry  = "RETRY"
      case abort  = "ABORT"
    }
    
    enum CodingKeys: String, CodingKey {
      case errorMessage = "error"
      case isUserError = "usererror"
      case errorCode
      case title
      case recovery = "recoveryTitle"
      case url
      case option = "recovery"
    }
  }
}
