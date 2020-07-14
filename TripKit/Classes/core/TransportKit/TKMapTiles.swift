//
//  TKMapTiles.swift
//  TripKit
//
//  Created by Adrian Schönig on 13.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

/// This class encapsulates information about the map tiles of a trip segment.
public class TKMapTiles: NSObject, Codable {
  
  /// A human-friendly name for these tiles
  public let name: String
  
  /// A list of URL templates to fetch the tiles. Can be multiple to not hit a single server with too many requests in parallel.
  public let urlTemplates: [String]
  
  /// Attributions to have to be displayed whenever the tiles are displayed
  public let sources: [TKAPI.DataAttribution]
  
}

extension TKMapTiles {
  
  /// Creating a new instance from a JSON object.
  ///
  /// - Parameter json: JSON object, typically obtained from server response
  /// - Returns: A new `TKMapTiles` instance.
  public static func newInstance(from json: [String: Any]?) -> TKMapTiles? {
    guard let json = json else { return nil }
    let decoder = JSONDecoder()
    return try? decoder.decode(TKMapTiles.self, withJSONObject: json)
  }
  
}
