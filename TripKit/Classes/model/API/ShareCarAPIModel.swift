//
//  ShareCarAPIModels.swift
//  TripKit
//
//  Created by Adrian Schönig on 29.10.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

// MARK: - Data Model

extension API {
  
  public struct SharedCar : Codable, Equatable {
    public let identifier: String?
    public let name: String?
    public let description: String?
    public let licensePlate: String?
    public let engineType: String?
    public let fuelType: String?
    public let fuelLevel: Int?
  }
  
  public struct BookingAvailability: Codable, Equatable {
    public enum Status: String, Codable {
      case available = "AVAILABLE"
      case notAvailable = "NOT_AVAILABLE"
      case unknown = "UNKNOWN"
    }
    
    public struct Interval: Codable, Equatable {
      public let status: Status
      public let start: Date?
      public let end: Date?
    }
    
    public let lastUpdated: Date
    public let intervals: [Interval]
  }
  
}

// MARK: - Convenience functions

extension API.BookingAvailability {
  public func getAvailability(at date: Date) -> API.BookingAvailability.Interval? {
    return intervals.first { $0.contains(date) }
  }
  
  public func getAvailability(start: Date, end: Date) -> API.BookingAvailability.Interval? {
    // TODO: This logic is likely broken
    return intervals.first { $0.contains(start) && $0.contains(end) }
  }
}

extension API.BookingAvailability.Interval {
  fileprivate func contains(_ date: Date) -> Bool {
    if let start = start {
      if let end = end {
        return start <= date && date <= end
      } else {
        return start <= date
      }
    } else if let end = end {
      return date <= end
    } else {
      return true
    }
  }
}
