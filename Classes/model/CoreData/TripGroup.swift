//
//  TripGroup.swift
//  Pods
//
//  Created by Adrian Schoenig on 3/4/17.
//
//

import Foundation
import Marshal

extension TripGroup {

  public var sources: [TKDataAttribution] {
    get {
      guard let sourcesRaw = sourcesRaw else { return [] }
      
      return sourcesRaw.flatMap { rawSource -> TKDataAttribution? in
        guard let marshaled = rawSource as? MarshaledObject else { return nil }
        return try? TKDataAttribution(object: marshaled)
      }
    }
  }
  
}
