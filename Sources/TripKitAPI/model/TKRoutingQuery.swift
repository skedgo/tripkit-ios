//
//  TKRoutingQuery.swift
//  TripKit
//
//  Created by Adrian Schönig on 20/11/2024.
//

import Foundation

public enum TKRoutingQueryTime: Equatable {
  case leaveASAP
  case leaveAfter(Date)
  case arriveBy(Date)
}

public struct TKRoutingQuery<Context> {
  public var from: TKAPI.Location
  public var to: TKAPI.Location
  public var at: TKRoutingQueryTime = .leaveASAP
  public var modes: Set<String>
  public var additional: Set<URLQueryItem> = []
  public var context: Context? = nil

  public init(from: TKAPI.Location, to: TKAPI.Location, at time: TKRoutingQueryTime = .leaveASAP, modes: Set<String>, additional: Set<URLQueryItem> = [], context: Context?) {
    self.from = from
    self.to = to
    self.at = time
    self.modes = modes
    self.additional = additional
    self.context = context
  }
}

extension TKRoutingQuery where Context == Never {
  public init(from: TKAPI.Location, to: TKAPI.Location, at time: TKRoutingQueryTime = .leaveASAP, modes: Set<String>, additional: Set<URLQueryItem> = []) {
    self.from = from
    self.to = to
    self.at = time
    self.modes = modes
    self.additional = additional
    self.context = nil
  }
}

extension TKRoutingQuery where Context == Never {
  /// Extracts the query details from a TripGo API-compatible deep link
  /// - parameter url: TripGo API-compatible deep link
  public init?(url: URL) {
    guard
      let components = NSURLComponents(url: url, resolvingAgainstBaseURL: false),
      let items = components.queryItems
    else { return nil }
    
    // get the input from the query
    var tlat, tlng: Double?
    var name: String?
    var flat, flng: Double?
    var type: Int?
    var time: Date?
    var modes: [String] = .init()
    for item in items {
      guard let value = item.value, !value.isEmpty else { continue }
      switch item.name {
      case "tlat":  tlat = Double(value)
      case "tlng":  tlng = Double(value)
      case "tname": name = value
      case "flat":  flat = Double(value)
      case "flng":  flng = Double(value)
      case "type":  type = Int(value)
      case "time":
        guard let date = Self.parseDate(value) else { continue }
        time = date
      case "modes", "mode":
        modes.append(value)
      default:
        continue
      }
    }
    
    func coordinate(lat: Double?, lng: Double?, name: String?) -> TKAPI.Location {
      if let lat, let lng {
        return TKAPI.Location(latitude: lat, longitude: lng, name: name)
      } else {
        return TKAPI.Location(latitude: -180, longitude: -180, name: name)
      }
    }
    
    // we need a to coordinate OR a name
    let to = coordinate(lat: tlat, lng: tlng, name: name)
    guard to.isValid else {
      return nil
    }
    
    // we're good to go, construct the time and from info
    let timeType: TKRoutingQueryTime
    if let type = type {
      switch (type, time != nil) {
      case (1, true): timeType = .leaveAfter(time!)
      case (2, true): timeType = .arriveBy(time!)
      default:        timeType = .leaveASAP
      }
    } else {
      timeType = .leaveASAP
    }
    
    self.init(
      from: coordinate(lat: flat, lng: flng, name: nil),
      to: to,
      at: timeType,
      modes: Set(modes),
      additional: []
    )
  }
}

extension TKRoutingQuery {
  
  public static func parseDate(_ object: Any?) -> Date? {
    if let string = object as? String {
      if let interval = TimeInterval(string), interval > 1000000000, interval < 2000000000 {
        return Date(timeIntervalSince1970: interval)
      }
      return try? Date(iso8601: string)
      
    } else if let interval = object as? TimeInterval, interval > 0 {
      return Date(timeIntervalSince1970: interval)
      
    } else {
      return nil
    }
  }
  
  
  static func requestString(for location: TKAPI.Location, includeAddress: Bool = true) -> String {
    guard includeAddress, let address = location.address else {
      return String(format: "(%f,%f)", location.latitude, location.longitude)
    }
    
    return String(format: "(%f,%f)\"%@\"", location.latitude, location.longitude, address)
  }
}

public extension TKAPI.Location {
  var isValid: Bool {
    return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180
  }
}
