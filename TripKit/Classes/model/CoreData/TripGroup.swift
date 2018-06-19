//
//  TripGroup.swift
//  Pods
//
//  Created by Adrian Schoenig on 3/4/17.
//
//

import Foundation

extension TripGroup {

  public var sources: [API.DataAttribution] {
    get {
      guard let sourcesRaw = sourcesRaw else { return [] }
      
      return sourcesRaw.compactMap { rawSource -> API.DataAttribution? in
        let decoder = JSONDecoder()
        return try? decoder.decode(API.DataAttribution.self, withJSONObject: rawSource)
      }
    }
  }
  
}
