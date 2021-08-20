//
//  GeocodeAPIModel.swift
//  TripKit
//
//  Created by Adrian Schönig on 13/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKAPI {
  
  struct GeocodeResponse: Decodable {
    let query: String
    let error: String?
    
    @DefaultEmptyArray var choices: [GeocodeChoice]
  }
  
  enum GeocodeChoice: Decodable {
    case location(TKNamedCoordinate)
    case stop(TKStopCoordinate)
    
    init(from decoder: Decoder) throws {
      if let stop = try? TKStopCoordinate(from: decoder) {
        self = .stop(stop)
      } else if let named = try? TKNamedCoordinate(from: decoder) {
        self = .location(named)
      } else {
        throw DecodingError.typeMismatch(TKNamedCoordinate.self, .init(codingPath: decoder.codingPath, debugDescription: "Expected TKStopCoordinate or TKNamedCoordinate."))
      }
    }
  }
  
}
