//
//  EventAPIModel.swift
//  TripKit-iOS
//
//  Created by Kuan Lun Huang on 13/5/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKAPI {
  
  public struct EventsResponse: Codable, Hashable, Sendable {
    public static let empty: EventsResponse = EventsResponse(events: [])
    
    public let events: [Event]
    
    public struct Event: Codable, Hashable, Sendable {
      public let description: String
      public let displayImage: String?
      public let endTime: Date?
      public let id: String
      public let location: Location
      public let startTime: Date?
      public let title: String
      public let url: URL?
      public let icon: Icon?
    }
    
    public struct Location: Codable, Hashable, Sendable {
      public let lat: Double
      public let lng: Double
    }
    
    public struct Icon: Codable, Hashable, Sendable {
      public let remoteIcon: String
      public let remoteIconIsTemplate: Bool?
    }
  }
  
}
