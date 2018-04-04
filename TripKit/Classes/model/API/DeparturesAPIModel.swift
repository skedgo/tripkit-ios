//
//  DeparturesAPIModel.swift
//  TripKit
//
//  Created by Adrian Schoenig on 22.09.17.
//

import Foundation

extension API {

  public struct Departures: Codable, Equatable {
    
    public struct Embarkations: Codable, Equatable {
      let services: [Departure]
      let stopCode: String
    }
    
    let alerts: [Alert]?
    let embarkationStops: [Embarkations]
    let parentStops: [Stop]?
    let stops: [Stop]?
  }
  
}
