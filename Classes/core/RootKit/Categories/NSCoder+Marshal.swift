//
//  NSCoder+Marshal.swift
//  Pods
//
//  Created by Adrian Schoenig on 3/1/17.
//
//

import Foundation

import Marshal

extension NSCoder {

  
  /// Decodes and returns an object that was previously encoded
  /// using a `NSCoder` or that can be initialised from the encoded
  /// object using Marshal.
  ///
  /// When using Marshal the marshaled-version (such as a JSON-like
  /// dictionary) has been encoded so there's a slight overhead
  /// of double decoding (first decoding the dictionary and then
  /// unmarshaling the object).
  ///
  /// - Parameter key: Key to look up the encoded object
  public func decodeOrUnmarshal<A: Unmarshaling>(forKey key: String) -> A? {
    if let object = decodeObject(forKey: key) as? A {
      return object
      
    } else if let marshaled = decodeObject(forKey: key) as? MarshaledObject,
      let object: A = try? A(object: marshaled) {
      return object
      
    } else {
      return nil
    }
  }
  
  
}

extension NSCoder : MarshaledObject {

  public func optionalAny(for key: KeyType) -> Any? {
    guard let aKey = key as? String else { return nil }
    return decodeObject(forKey: aKey)
  }
  
}
