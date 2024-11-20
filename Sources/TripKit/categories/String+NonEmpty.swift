//
//  String+NonEmpty.swift
//  TripKit
//
//  Created by Adrian Schönig on 2/12/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension String {
  var nonEmpty: String? {
    return isEmpty ? nil : self
  }
  
  var trimmedNonEmpty: String? {
    trimmingCharacters(in: .whitespaces).nonEmpty
  }
}

extension Optional where Wrapped == String {
  var isEmpty: Bool {
    switch self {
    case .none: return true
    case .some(let string): return string.isEmpty
    }
  }
  
  var nonEmpty: String? {
    return isEmpty ? nil : self
  }
}
