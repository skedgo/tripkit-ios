//
//  TKInfoTypes.swift
//  TripKit
//
//  Created by Adrian Schoenig on 28/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import Marshal

public struct TKCompanyInfo : Unmarshaling {
  public let name: String
  public let website: String?
  public let remoteIcon: String?
  
  public init(object: MarshaledObject) throws {
    name        = try  object.value(for: "name")
    website     = try? object.value(for: "website")
    remoteIcon  = try? object.value(for: "remoteIcon")
  }
}


public struct TKDataAttribution : Unmarshaling {
  public let provider: TKCompanyInfo
  public let disclaimer: String?
  
  public init(object: MarshaledObject) throws {
    provider    = try  object.value(for: "provider")
    disclaimer  = try? object.value(for: "disclaimer")
  }
}


public struct TKOpeningHours : Unmarshaling {
  
  let timeZone: TimeZone
  let days: [Day]
  
  public struct Day: Unmarshaling {
    
    let day: DayOfWeek
    let times: [Time]
    
    public struct Time: Unmarshaling {
      
      let opens: String
      let closes: String
      
      public init(object: MarshaledObject) throws {
        opens   = try object.value(for: "opens")
        closes  = try object.value(for: "closes")
      }
    }
    
    public enum DayOfWeek: String {
      case monday         = "MONDAY"
      case tuesday        = "TUESDAY"
      case wednesday      = "WEDNESDAY"
      case thursday       = "THURSDAY"
      case friday         = "FRIDAY"
      case saturday       = "SATURDAY"
      case sunday         = "SUNDAY"
      case publicHoliday  = "PUBLIC_HOLIDAY"
    }
    
    public init(object: MarshaledObject) throws {
      day   = try object.value(for: "name")
      times = try object.value(for: "times")
    }
    
  }
  
  public init(object: MarshaledObject) throws {
    timeZone = try object.value(for: "timeZone")
    days     = try object.value(for: "days")
  }
  
}


// MARK: - Helper Extensions -

fileprivate enum TKInfoTypeParserError: Error {
  case badTimeZoneIdentifier(String)
}


extension Date: ValueType {
  public static func value(from object: Any) throws -> Date {
    guard let seconds = object as? TimeInterval else {
      throw MarshalError.typeMismatch(expected: TimeInterval.self, actual: type(of: object))
    }
    return Date(timeIntervalSince1970: seconds)
  }
}


extension TimeZone: ValueType {
  public static func value(from object: Any) throws -> TimeZone {
    guard let identifier = object as? String else {
      throw MarshalError.typeMismatch(expected: String.self, actual: type(of: object))
    }
    guard let timeZone = TimeZone(identifier: identifier) else {
      throw TKInfoTypeParserError.badTimeZoneIdentifier(identifier)
    }
    return timeZone
  }
}
