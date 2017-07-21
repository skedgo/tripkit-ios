//
//  TKAgendaOutput.swift
//  TripKit
//
//  Created by Adrian Schoenig on 13/6/17.
//

import Foundation

import Marshal

public struct TKAgendaOutput {
  
  public enum TrackItem {
    case home(id: String, arrival: Date?, departure: Date?)
    case includedEvent(id: String, arrival: Date, departure: Date)
    case excludedEvent(id: String)
    case trip(fromId: String, tripId: String, toId: String)
  }
  
  public let hashCode: Int
  
  public let track: [TrackItem]
  
//  public let inputs: [String: TKAgendaInput.Item]
  
  /// Map of a trip's ID to the trip. A trip's ID here
  /// is the trip's departure string from the output.
  public var trips: [String: Trip] = [:]
  
}

// MARK: Unmarshaling

extension TKAgendaOutput: Unmarshaling {
  
  public init(object: MarshaledObject) throws {
    
    hashCode = try object.value(for: "hashCode")
    track = try object.value(for: "track")
//    inputs = try object.value(for: "inputs")
    
  }
  
}

extension TKAgendaOutput.TrackItem: Unmarshaling {

  public init(object: MarshaledObject) throws {
    
    let klass: String = try object.value(for: "class")
    let id: String? = try? object.value(for: "id")
    
    switch klass {
    case "event":
      guard let id = id else { throw MarshalError.nullValue(key: "event.id") }
      let effectiveStart: Date? = try? object.value(for: "effectiveStart")
      let effectiveEnd: Date? = try? object.value(for: "effectiveEnd")
      
      if id == "home" {
        self = .home(id: id, arrival: effectiveStart, departure: effectiveEnd)
      } else if let start = effectiveStart, let end = effectiveEnd {
        self = .includedEvent(id: id, arrival: start, departure: end)
      } else {
        self = .excludedEvent(id: id)
      }
      
    case "trip":
      let fromId: String = try object.value(for: "fromId")
      let toId: String = try object.value(for: "toId")

      if let id = id {
        self = .trip(fromId: fromId, tripId: id, toId: toId)
      } else {
        
        let tripId = try TKAgendaOutput.tripId(forTrackItem: object)
        self = .trip(fromId: fromId, tripId: tripId, toId: toId)
      }
      
    default:
      throw MarshalError.keyNotFound(key: "class")
      
    }
    
  }
}

extension TKAgendaOutput {

  static func tripId(forTrackItem object: MarshaledObject) throws -> String {
    guard
      let groups: [[String: Any]] = try object.value(for: "groups"),
      let group = groups.first,
      let trips: [[String: Any]] = try group.value(for: "trips"),
      let departureId = trips.first?["depart"] as? String
      else {
        throw MarshalError.keyNotFound(key: "groups[0].trips[0].depart")
    }
    
    return departureId
  }
  
}
