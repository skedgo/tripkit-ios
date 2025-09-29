//
//  AlertAPIModels.swift
//  TripKit
//
//  Created by Adrian Schoenig on 23.09.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension TKAPI {
  
  public struct Alert: Codable, Hashable, Sendable {
    public enum Severity: String, Codable, Sendable {
      case info = "info"
      case warning = "warning"
      case alert = "alert"
    }
    
    public struct Action: Hashable, Sendable {
      public enum ActionType: Hashable, Sendable {
        case reroute([String])
      }
      
      public let text: String
      public let type: ActionType
    }
    
    public let title: String
    public let text: String?
    public let url: URL?
    public let fromDate: Date?
    public let toDate: Date?
    public let lastUpdated: Date?
    public let remoteIcon: URL?
    public let severity: Severity
    public let hashCode: Int

    public let action: Action?
    public let location: TKAPI.Location?
    public let serviceTripID: String?
    
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
      serviceTripID = try? container.decode(String.self, forKey: .serviceTripID)
      lastUpdated  = try? container.decode(Date.self, forKey: .lastUpdated)
      fromDate   = try? container.decode(Date.self, forKey: .fromDate)
      toDate     = try? container.decode(Date.self, forKey: .toDate)
    }
  }
  
  /// Replaces the previous `TKAlertWrapper`
  public struct AlertMapping: Codable, Hashable, Sendable {
    public let alert: TKAPI.Alert
    public let operators: [String]?
    public let serviceTripIDs: [String]?
    public let stopCodes: [String]?
    public let routes: [AlertRouteMapping]?
    public let modeInfo: TKModeInfo?
  }
  
  public struct AlertRouteMapping: Codable, Hashable, Sendable {
    public let id: String
    public let name: String?
    public let number: String?
    public let modeInfo: TKModeInfo
    
#if !os(Linux)
    /// This color applies to an individual service.
    public var color: TKColor? { return modeInfo.color }
#endif
  }
  
}

extension TKAPI.Alert.Action: Codable {
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
