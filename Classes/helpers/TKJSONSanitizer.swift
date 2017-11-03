//
//  TKJSONSanitizer.swift
//  TripKit
//
//  Created by Adrian Schönig on 03.11.17.
//

import Foundation

public enum TKJSONSanitizer {
  
  /// Sanitizes the provided input to be JSON compatible03
  ///
  /// Primarily used for handling URLs, UIColors and TimeZones
  ///
  /// - Parameter input: Any object that should be made JSON compatible
  /// - Returns: JSON compatible version or `nil` if not possible
  public static func sanitize(_ input: Any) -> Any? {
    switch input {
    
    case is String, is Int, is Double, is Float, is Bool:
      return input
      
    case is NSNull, is NSNumber:
      return input
    
    case is URL:
      return (input as! URL).absoluteString
    
    case is UIColor:
      let rgb = API.RGBColor(for: input as! UIColor)
      return try? JSONEncoder().encodeJSONObject(rgb)
      
    case is TimeZone:
      return (input as! TimeZone).identifier
    
    case is [String: Any]:
      let dict = input as! [String: Any]
      return dict.mapValues(sanitize)
        .filter { _, value in value != nil }
        .mapValues { $0! }
    
    case is [Any]:
      let array = input as! [Any]
      return array.flatMap(sanitize)
      
    default:
      return nil
    }
  }
  
}
