//
//  AlertAPIModels.swift
//  TripKit
//
//  Created by Adrian Schoenig on 23.09.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension API {
  public struct Alert: Codable {
    public enum Severity: String, Codable {
      case info = "info"
      case warning = "warning"
      case alert = "alert"
    }
    
    public struct Action {
      enum ActionType {
        case reroute([String])
      }
      
      let text: String
      let type: ActionType
    }
    
    let hashCode: Int
    let severity: Severity
    let title: String
    let text: String?
    let url: URL?
    let action: Action?
    
    let remoteIcon: URL?
    let location: API.Location?
    let lastUpdate: TimeInterval?
    let startTime: TimeInterval?
    let endTime: TimeInterval?
    
    // MARK: - Codable
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      hashCode    = try container.decode(Int.self, forKey: .hashCode)
      severity    = try container.decode(Severity.self, forKey: .severity)
      title       = try container.decode(String.self, forKey: .title)
      text        = try? container.decode(String.self, forKey: .text)
      url         = try? container.decode(URL.self, forKey: .url)
      action      = try? container.decode(Action.self, forKey: .action)
      remoteIcon  = try? container.decode(URL.self, forKey: .remoteIcon)
      location    = try? container.decode(Location.self, forKey: .location)
      lastUpdate  = try? container.decode(TimeInterval.self, forKey: .lastUpdate)
      startTime   = try? container.decode(TimeInterval.self, forKey: .startTime)
      endTime     = try? container.decode(TimeInterval.self, forKey: .endTime)
    }
  }
  
  /// Replaces the previous `TKAlertWrapper`
  public struct AlertMapping: Codable {
    public let alert: API.Alert
    public let operators: [String]?
    public let serviceTripIDs: [String]?
    public let stopCodes: [String]?
    public let routeIDs: [String]?
  }
}

extension API.Alert.Action: Codable {
  private enum CodingKeys: String, CodingKey {
    case text
    case type
    case excludedStopCodes
  }
  
  enum CodingError: Error {
    case unknownType(String)
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    text = try container.decode(String.self, forKey: .text)
    
    let type = try container.decode(String.self, forKey: .type)
    switch type {
    case "rerouteExcludingStops":
      let excludedStops = try container.decode([String].self, forKey: .excludedStopCodes)
      self.type = .reroute(excludedStops)
    default:
      throw CodingError.unknownType("Decoding Error: \(dump(container))")
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(text, forKey: .text)
    
    switch type {
    case .reroute(let excludedStops):
      try container.encode("rerouteExcludingStops", forKey: .type)
      try container.encode(excludedStops, forKey: .excludedStopCodes)
    }
  }
}