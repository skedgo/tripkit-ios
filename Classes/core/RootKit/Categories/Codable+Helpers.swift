//
//  Codable+Helpers.swift
//  TripKit
//
//  Created by Adrian Schoenig on 26.09.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

// MARK: - Helper for Codable + JSON

extension JSONEncoder {
  public func encodeJSONObject<T: Encodable>(_ value: T, options opt: JSONSerialization.ReadingOptions = []) throws -> Any {
    let data = try encode(value)
    return try JSONSerialization.jsonObject(with: data, options: opt)
  }
}

extension JSONDecoder {
  public func decode<T: Decodable>(_ type: T.Type, withJSONObject object: Any, options opt: JSONSerialization.WritingOptions = []) throws -> T {
    let data = try JSONSerialization.data(withJSONObject: object, options: opt)
    return try decode(T.self, from: data)
  }
}
