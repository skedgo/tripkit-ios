//
//  ISO8601OrSecondsSince1970.swift
//  TripKit
//
//  Created by Adrian Schönig on 10/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

// MARK: - ISO8601

@propertyWrapper
public struct ISO8601 {
  public init(wrappedValue: Date) {
    self.wrappedValue = wrappedValue
  }
  
  public var wrappedValue: Date
}

extension ISO8601: Decodable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let text = try container.decode(String.self)
    wrappedValue = try Date(iso8601: text)
  }
}

extension ISO8601: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(wrappedValue.iso8601)
  }
}


extension ISO8601: Equatable {}
extension ISO8601: Hashable {}

// MARK: - OptionalISO8601

@propertyWrapper
public struct OptionalISO8601 {
  public init(wrappedValue: Date?) {
    self.wrappedValue = wrappedValue
  }
  
  public var wrappedValue: Date?
}

extension OptionalISO8601: Decodable {
  public init(from decoder: Decoder) throws {
    do {
      let container = try decoder.singleValueContainer()
      let text = try container.decode(String.self)
      wrappedValue = try Date(iso8601: text)
    } catch {
      wrappedValue = nil
    }
  }
}

extension OptionalISO8601: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    if let value = wrappedValue {
      try container.encode(value.iso8601)
    }
  }
}


extension OptionalISO8601: Equatable {}
extension OptionalISO8601: Hashable {}

extension KeyedDecodingContainer {
  public func decode(_ type: OptionalISO8601.Type, forKey key: Self.Key) throws -> OptionalISO8601 {
      return try decodeIfPresent(type, forKey: key) ?? OptionalISO8601(wrappedValue: nil)
  }
}



// MARK: - ISO8601OrSecondsSince1970

@propertyWrapper
public struct ISO8601OrSecondsSince1970 {
  public init(wrappedValue: Date) {
    self.wrappedValue = wrappedValue
  }
  
  public var wrappedValue: Date
}

extension ISO8601OrSecondsSince1970: Decodable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let seconds = (try? container.decode(TimeInterval.self)) {
      wrappedValue = Date(timeIntervalSince1970: seconds)
    } else {
      let text = try container.decode(String.self)
      wrappedValue = try Date(iso8601: text)
    }
  }
}

extension ISO8601OrSecondsSince1970: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(wrappedValue.iso8601)
  }
}


extension ISO8601OrSecondsSince1970: Equatable {}
extension ISO8601OrSecondsSince1970: Hashable {}

// MARK: - OptionalISO8601OrSecondsSince1970

@propertyWrapper
public struct OptionalISO8601OrSecondsSince1970 {
  public init(wrappedValue: Date?) {
    self.wrappedValue = wrappedValue
  }
  
  public var wrappedValue: Date?
}

extension OptionalISO8601OrSecondsSince1970: Decodable {
  public init(from decoder: Decoder) throws {
    do {
      let container = try decoder.singleValueContainer()
      if let seconds = (try? container.decode(TimeInterval.self)) {
        wrappedValue = Date(timeIntervalSince1970: seconds)
      } else {
        let text = try container.decode(String.self)
        wrappedValue = try Date(iso8601: text)
      }
    } catch {
      wrappedValue = nil
    }
  }
}

extension OptionalISO8601OrSecondsSince1970: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    if let value = wrappedValue {
      try container.encode(value.iso8601)
    }
  }
}


extension OptionalISO8601OrSecondsSince1970: Equatable {}
extension OptionalISO8601OrSecondsSince1970: Hashable {}

extension KeyedDecodingContainer {
  public func decode(_ type: OptionalISO8601OrSecondsSince1970.Type, forKey key: Self.Key) throws -> OptionalISO8601OrSecondsSince1970 {
      return try decodeIfPresent(type, forKey: key) ?? OptionalISO8601OrSecondsSince1970(wrappedValue: nil)
  }
}

