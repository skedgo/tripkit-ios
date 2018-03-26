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
    
    public let title: String
    public let text: String?
    public let url: URL?
    public let fromDate: Date?
    public let toDate: Date?
    public let lastUpdated: Date?
    public let remoteIcon: URL?
    public let severity: Severity
    
    let hashCode: Int    
    let action: Action?    
    let location: API.Location?
  }
  
  /// Replaces the previous `TKAlertWrapper`
  public struct AlertMapping: Codable {
    public let alert: API.Alert
    public let operators: [String]?
    public let serviceTripIDs: [String]?
    public let stopCodes: [String]?
    public let routes: [API.Route]?
    public let modeInfo: ModeInfo?
  }
  
  public struct Route: Codable {
    public let id: String
    public let name: String?
    public let number: String?
    public let modeInfo: ModeInfo
    
    /// This color applies to an individual service.
    public var color: UIColor? { return modeInfo.color }
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
