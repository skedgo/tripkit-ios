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




// MARK: - Helper Extensions -

extension Date: ValueType {
  public static func value(from object: Any) throws -> Date {
    guard let seconds = object as? TimeInterval else {
      throw MarshalError.typeMismatch(expected: TimeInterval.self, actual: type(of: object))
    }
    return Date(timeIntervalSince1970: seconds)
  }
}
