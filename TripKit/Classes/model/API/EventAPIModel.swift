//
//  EventAPIModel.swift
//  TripKit-iOS
//
//  Created by Kuan Lun Huang on 13/5/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension API {
  
  public struct EventsResponse: Codable, Equatable {
    public static let empty: EventsResponse = EventsResponse(events: [])
    
    public let events: [Event]
    
    public struct Event: Codable, Equatable {
      public let description: String
      public let endTime: Date?
      public let id: String
      public let location: Location
      public let startTime: Date?
      public let title: String
      public let url: URL?
    }
    
    public struct Location: Codable, Equatable {
      public let lat: Double
      public let lng: Double
    }
  }
  
}
