//
//  TKAgendaSummary.swift
//  TripKit
//
//  Created by Adrian Schoenig on 26/7/17.
//

import Foundation

import Marshal

public struct TKAgendaSummary {
  
  public struct Day {
    public let date: DateComponents
    public let isComputed: Bool
    public let hasTrips: Bool?
    public let highestPriority: Int
  }
  
  public let days: [Day]
  
}

// MARK: Unmarshaling

extension TKAgendaSummary: Unmarshaling {
  
  public init(object: MarshaledObject) throws {
    days = try object.value(for: "dates")
  }
  
}

extension TKAgendaSummary.Day: Unmarshaling {
  
  public init(object: MarshaledObject) throws {
    date = try object.value(for: "date")
    isComputed = try object.value(for: "isComputed")
    hasTrips = try? object.value(for: "hasTrips")
    highestPriority = (try? object.value(for: "highestPriority")) ?? 0
  }
  
}

extension DateComponents: ValueType {
  public static func value(from object: Any) throws -> DateComponents {
    guard let string = object as? String else {
      throw MarshalError.typeMismatch(expected: String.self, actual: type(of: object))
    }
    
    let components = string.split(separator: "-").map(String.init)
    guard components.count == 3 else {
      throw MarshalError.typeMismatch(expected: String.self, actual: type(of: object))
    }
    
    return DateComponents(year: Int(components[0]), month: Int(components[1]), day: Int(components[2]))
  }
}
