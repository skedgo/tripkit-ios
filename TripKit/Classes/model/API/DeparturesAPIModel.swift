//
//  DeparturesAPIModel.swift
//  TripKit
//
//  Created by Adrian Schoenig on 22.09.17.
//

import Foundation

extension API {

  public struct Departures: Codable, Hashable {
    
    public struct Embarkations: Codable, Hashable {
      public let services: [Departure]
      public let stopCode: String
    }
    
    public let alerts: [Alert]?
    public let embarkationStops: [Embarkations]
    public let parentStops: [Stop]?
    public let stops: [Stop]?
  }
  
}
