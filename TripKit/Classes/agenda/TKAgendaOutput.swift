//
//  TKAgendaOutput.swift
//  TripKit
//
//  Created by Adrian Schoenig on 13/6/17.
//

import Foundation

public struct TKAgendaOutput: Decodable {
  
  public enum TrackItem: Decodable {
    case home(id: String, arrival: Date?, departure: Date?)
    case includedEvent(id: String, arrival: Date, departure: Date)
    case excludedEvent(id: String)
    case trip(fromId: String, tripId: String, toId: String)
    
    public var id: String {
      switch self {
      case .home(let id, _, _): return id
      case .includedEvent(let id, _, _): return id
      case .excludedEvent(let id): return id
      case .trip(_, let id, _): return id
      }
    }
    
    // MARK: Decodable
    
    private enum DecodingError: Error {
      case unexpectedType(String)
    }
    
    private enum CodingKeys: String, CodingKey {
      case klass = "class"
      case id
      case effectiveStart
      case effectiveEnd
      case fromId
      case toId
    }
    
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      
      let klass = try container.decode(String.self, forKey: .klass)
      let id = try container.decode(String.self, forKey: .id)
      switch klass {
      case "event":
        let start = try? container.decode(Date.self, forKey: .effectiveStart)
        let end = try? container.decode(Date.self, forKey: .effectiveEnd)
        
        if id == "home" {
          self = .home(id: id, arrival: start, departure: end)
        } else if let start = start, let end = end {
          self = .includedEvent(id: id, arrival: start, departure: end)
        } else {
          self = .excludedEvent(id: id)
        }
      
      case "trip":
        let fromId = try container.decode(String.self, forKey: .fromId)
        let toId = try container.decode(String.self, forKey: .toId)
        self = .trip(fromId: fromId, tripId: id, toId: toId)
        
      default:
        throw DecodingError.unexpectedType(klass)
      }
    }
  }
  
  public let hashCode: Int
  
  public let track: [TrackItem]
  
  public let inputs: [String: TKAgendaInput.Item]
  
  /// Map of a trip's ID to the trip
  public var trips: [String: Trip] = [:]
  
  
  // MARK: Decodable
  
  private enum CodingKeys: String, CodingKey {
    case hashCode
    case track
    case inputs
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    hashCode = try container.decode(Int.self, forKey: .hashCode)
    track = try container.decode([TrackItem].self, forKey: .track)
    inputs = try container.decode([String: TKAgendaInput.Item].self, forKey: .inputs)
  }
  
}
