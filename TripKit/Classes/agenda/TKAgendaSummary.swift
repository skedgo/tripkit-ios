//
//  TKAgendaSummary.swift
//  TripKit
//
//  Created by Adrian Schoenig on 26/7/17.
//

import Foundation

public struct TKAgendaSummary: Decodable {
  
  public struct Day: Decodable {
    public let date: DateComponents
    public let isComputed: Bool
    public let hasTrips: Bool?
    public let highestPriority: Int
    
    // MARK: Decodable
    
    private enum CodingKeys: String, CodingKey {
      case date
      case isComputed
      case hasTrips
      case highestPriority
    }
    
    private enum DecodingError: Error {
      case badDate(String)
    }
    
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      isComputed = try container.decode(Bool.self, forKey: .isComputed)
      hasTrips = try? container.decode(Bool.self, forKey: .hasTrips)
      highestPriority = (try? container.decode(Int.self, forKey: .highestPriority)) ?? 0
      
      let dateString = try container.decode(String.self, forKey: .date)
      let components = dateString.split(separator: "-").map(String.init)
      guard components.count == 3 else {
        throw DecodingError.badDate(dateString)
      }
      date = DateComponents(year: Int(components[0]), month: Int(components[1]), day: Int(components[2]))
    }
    
  }
  
  public let days: [Day]
  
  private enum CodingKeys: String, CodingKey {
    case days = "dates"
  }
}
