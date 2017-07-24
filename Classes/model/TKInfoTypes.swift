//
//  TKInfoTypes.swift
//  TripKit
//
//  Created by Adrian Schoenig on 28/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import Marshal

public struct TKCompanyInfo : Unmarshaling, Marshaling {
  public let name: String
  public let website: URL?
  public let phone: String?
  public let remoteIcon: String?
  public let remoteDarkIcon: String?
  public let color: SGKColor?
  
  public init(object: MarshaledObject) throws {
    name            = try  object.value(for: "name")
    website         = try? object.value(for: "website")
    phone           = try? object.value(for: "phone")
    remoteIcon      = try? object.value(for: "remoteIcon")
    remoteDarkIcon  = try? object.value(for: "remoteDarkIcon")
    color           = try? object.value(for: "color")
  }
  
  public typealias MarshalType = [String: Any]
  
  public func marshaled() -> MarshalType {
    var marshaled: MarshalType =  [
      "name": name,
    ]
    
    marshaled["website"] = website
    marshaled["phone"] = phone
    marshaled["remoteIcon"] = remoteIcon
    marshaled["remoteDarkIcon"] = remoteDarkIcon
    marshaled["color"] = color
    return marshaled
  }
}

public struct TKDataAttribution : Unmarshaling, Marshaling {
  public let provider: TKCompanyInfo
  public let disclaimer: String?
  
  public init(object: MarshaledObject) throws {
    provider    = try  object.value(for: "provider")
    disclaimer  = try? object.value(for: "disclaimer")
  }
  
  public typealias MarshalType = [String: Any]
  
  public func marshaled() -> MarshalType {
    var marshaled : MarshalType =  [
      "provider": provider.marshaled(),
      ]
    
    marshaled["disclaimer"] = disclaimer
    return marshaled
  }
}

// MARK: - Helper Extensions -

extension TKCompanyInfo {
  
  public var remoteIconURL: URL? {
    guard let fileNamePart = remoteIcon else {
      return nil
    }
    
    return SVKServer.imageURL(forIconFileNamePart: fileNamePart, of: .listMainMode)
  }
  
  public var remoteDarkIconURL: URL? {
    guard let fileNamePart = remoteDarkIcon else {
      return nil
    }
    
    return SVKServer.imageURL(forIconFileNamePart: fileNamePart, of: .listMainMode)
  }
  
}

extension Date: ValueType {
  public static func value(from object: Any) throws -> Date {
    guard let seconds = object as? TimeInterval else {
      throw MarshalError.typeMismatch(expected: TimeInterval.self, actual: type(of: object))
    }
    return Date(timeIntervalSince1970: seconds)
  }
}
