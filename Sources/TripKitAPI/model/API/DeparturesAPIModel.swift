//
//  DeparturesAPIModel.swift
//  TripKit
//
//  Created by Adrian Schoenig on 22.09.17.
//

import Foundation

extension TKAPI {

  /// Output data model for `departures.json`
  public struct Departures: Codable, Hashable, Sendable {
    
    public struct Embarkations: Codable, Hashable, Sendable {
      public let services: [Departure]
      public let stopCode: String
    }
    
    public let alerts: [Alert]?
    public let embarkationStops: [Embarkations]
    public let parentStops: [Stop]?
    public let stops: [Stop]?
  }
  
}
