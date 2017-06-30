//
//  Sequence+Reduce.swift
//  Pods
//
//  Created by Adrian Schoenig on 20/1/17.
//
//

import Foundation

extension Sequence {
  
  /// A variant of reduce that's using `inout` which can provide significant
  /// performance increases
  ///
  /// - Note: Will likely become part of Foundation, see [proposal](https://github.com/apple/swift-evolution/pull/587/files)
  ///
  /// - Parameters:
  ///   - initial: Initial value
  ///   - combine: Method called one ach element in the sequence
  /// - Returns: Resulting sequence
  public func reduce<A>(mutating initial: A, combine: (inout A, Iterator.Element) -> ()) -> A {
    var result = initial
    for element in self {
      combine(&result, element)
    }
    return result
  }
  
}
