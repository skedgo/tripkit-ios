//
//  TripGroup.swift
//  Pods
//
//  Created by Adrian Schoenig on 3/4/17.
//
//

import Foundation

extension TripGroup {

  public var sources: [TKAPI.DataAttribution] {
    get {
      guard let sourcesRaw = sourcesRaw else { return [] }
      
      return sourcesRaw.compactMap { rawSource -> TKAPI.DataAttribution? in
        let decoder = JSONDecoder()
        return try? decoder.decode(TKAPI.DataAttribution.self, withJSONObject: rawSource)
      }
    }
    set {
      do {
        let encoded = try JSONEncoder().encodeJSONObject(newValue)
        self.sourcesRaw = (encoded as? [NSCoding & NSObjectProtocol]) ?? []
      } catch {
        TKLog.warn("Error saving sources: \(error)")
      }
    }
  }
  
}
