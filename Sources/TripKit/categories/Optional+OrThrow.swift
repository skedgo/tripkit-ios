//
//  Optional+OrThrow.swift
//  TripKit
//
//  Created by Adrian Schönig on 19/11/2024.
//

extension Optional {
  
  func orThrow(_ error: Error) throws -> Wrapped {
    switch self {
    case .none: throw error
    case .some(let wrapped): return wrapped
    }
  }
  
}
