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
    
    let hashCode: Int
    let severity: Severity
    let title: String
    let text: String?
    let url: URL?
    
    let remoteIcon: URL?
    let location: API.Location?
    let lastUpdate: TimeInterval?
    let startTime: TimeInterval?
    let endTime: TimeInterval?
    
    // FIXME: Add action again
    
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
