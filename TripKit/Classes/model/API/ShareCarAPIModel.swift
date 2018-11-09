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
  
  public struct SharedCar : Codable, Hashable {
    public let identifier: String?
    public let name: String?
    public let description: String?
    public let licensePlate: String?
    public let engineType: String?
    public let fuelType: String?
    public let fuelLevel: Int?
  }
  
  public struct BookingAvailability: Codable, Hashable {
    public enum Status: String, Codable {
      case available = "AVAILABLE"
      case notAvailable = "NOT_AVAILABLE"
      case unknown = "UNKNOWN"
    }
    
    public struct Interval: Codable, Hashable {
      public let status: Status
      public let start: Date?
      public let end: Date?
    }
    
    public let lastUpdated: Date
    public let intervals: [Interval]
  }
  
  public struct CarAvailability: Codable, Hashable {
    public let car: SharedCar
    public let availability: BookingAvailability?
    public let bookingURL: String?
  }
  
}

// MARK: - Convenience functions

extension API.BookingAvailability {
  public func getAvailability(at date: Date) -> API.BookingAvailability.Interval? {
    return intervals.first { $0.contains(date) }
  }
  
  public func getStatus(start: Date, end: Date) -> API.BookingAvailability.Status {
    let overlaps = intervals
      .filter { $0.overlaps(start: start, end: end) }
      .map { $0.status }
    
    // simple cases
    guard overlaps.count > 0, let first = overlaps.first else { return .unknown }
    guard overlaps.count > 1 else { return first }
    
    // if multiple overlaps, take the most pessimistic
    if overlaps.contains(.notAvailable) {
      return .notAvailable
    } else if overlaps.contains(.unknown) {
      return .unknown
    } else {
      assert(overlaps.contains(.available))
      return .available
    }
  }
}

extension API.BookingAvailability.Interval {
  fileprivate func contains(_ date: Date) -> Bool {
    if let start = start {
      if let end = end {
        return start <= date && date < end
      } else {
        return start <= date
      }
    } else if let end = end {
      return date < end
    } else {
      return true
    }
  }
  
  fileprivate func overlaps(start: Date, end: Date) -> Bool {
    if let myStart = self.start {
      if let myEnd = self.end {
        return myStart < end && start < myEnd
      } else {
        return myStart < end
      }
    } else if let myEnd = self.end {
      return start < myEnd
    } else {
      return true
    }
  }
}
