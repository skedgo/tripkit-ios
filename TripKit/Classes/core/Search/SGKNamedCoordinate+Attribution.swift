//
//  SGKNamedCoordinate+Attribution.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 25/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

public extension SGKNamedCoordinate {
  
  @objc var attributionIsVerified: NSNumber? {
    get {
      return data["isVerified"] as? NSNumber
    }
    set {
      data["isVerified"] = newValue
    }
  }
  
  public var dataSources: [API.DataAttribution] {
    get {
      guard let json = data["dataSources"] as Any?, let sanitized = TKJSONSanitizer.sanitize(json) else { return [] }
      return (try? JSONDecoder().decode([API.DataAttribution].self, withJSONObject: sanitized)) ?? []
    }
    set {
      data["dataSources"] = try? JSONEncoder().encodeJSONObject(newValue)
    }
  }
}
