//
//  TKSettings.swift
//  TripKit
//
//  Created by Adrian Schoenig on 4/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension TKSettings {
  
  public struct Config: Codable {
    public enum DistanceUnit: String, Codable {
      case auto
      case metric
      case imperial
    }
    
    public let version: Int
    public let distanceUnit: DistanceUnit
    public let weights: [Weight: Float]
    public let avoidModes: [String]
    public let concession: Bool
    public let wheelchair: Bool
    public let cyclingSpeed: Speed
    public let walkingSpeed: Speed
    public let maximumWalkingDuration: TimeInterval?
    public let minimumTransferTime: TimeInterval?
    public let emissions: [String: Float]
    public let bookingSandbox: Bool
    public let enableFlights: Bool
    public let twoWayHireCostIncludesReturn: Bool

    
    public enum Weight: String, Codable {
      case money
      case carbon
      case time
      case hassle
      case exercise
    }
    
    public enum Speed {
      case impaired
      case slow
      case medium
      case fast
      case custom(CLLocationSpeed)
    }
    
    private enum CodingKeys: String, CodingKey {
      case version = "v"
      case distanceUnit = "unit"
      case weights
      case avoidModes = "avoid"
      case walkingSpeed
      case cyclingSpeed
      case concession = "conc"
      case wheelchair
      case maximumWalkingDuration = "wm"
      case minimumTransferTime = "tt"
      case emissions = "co2"
      case bookingSandbox = "bsb"
      case enableFlights = "ef"
      case twoWayHireCostIncludesReturn = "2wirc"
    }
    
    public init() {
      let shared = UserDefaults.shared
      version = TKSettings.parserJsonVersion
      distanceUnit = Locale.current.usesMetricSystem ? .metric : .imperial
      weights = [
        .money:  shared.float(forKey: TKDefaultsKeyProfileWeightMoney),
        .carbon: shared.float(forKey: TKDefaultsKeyProfileWeightCarbon),
        .time:   shared.float(forKey: TKDefaultsKeyProfileWeightTime),
        .hassle: shared.float(forKey: TKDefaultsKeyProfileWeightHassle),
      ]
      avoidModes = TKUserProfileHelper.dislikedTransitModes
      concession = shared.bool(forKey: TKDefaultsKeyProfileTransportConcessionPricing)
      wheelchair = TKUserProfileHelper.showWheelchairInformation
      twoWayHireCostIncludesReturn = !TKSettings.ignoreCostToReturnCarHireVehicle
      
      cyclingSpeed = Speed(apiValue: shared.object(forKey: TKDefaultsKeyProfileTransportCyclingSpeed)) ?? .medium
      walkingSpeed = Speed(apiValue: shared.object(forKey: TKDefaultsKeyProfileTransportWalkSpeed)) ?? .medium

      // FIXME: FIX UP!
      maximumWalkingDuration = nil // shared.TKDefaultsKeyProfileTransportWalkMaxDuration
      minimumTransferTime = nil // shared.TKDefaultsKeyProfileTransportTransferTime

      emissions = (shared.object(forKey: TKDefaultsKeyProfileTransportEmissions) as? [String: Float]) ?? [:]
      
      bookingSandbox = false // if (DEBUG: setting OR true) else (setting OR false)
      enableFlights = shared.bool(forKey: SVKDefaultsKeyProfileEnableFlights)
    }
    
    public var paras: [String: Any] {
      var paras: [String: Any] = [
        "v": version,
        "unit": distanceUnit.rawValue,
        "wp": "(\(weights[.money] ?? 1.0),\(weights[.carbon] ?? 1.0),\(weights[.time] ?? 1.0),\(weights[.hassle] ?? 1.0))",
        "cs": cyclingSpeed.apiValue,
        "ws": walkingSpeed.apiValue,
      ]
      if !avoidModes.isEmpty { paras["avoid"] = avoidModes }
      if concession { paras["conc"] = true }
      if wheelchair { paras["wheelchair"] = true }
      if let wm = maximumWalkingDuration { paras["wm"] = wm/60 }
      if let tt = minimumTransferTime { paras["tt"] = tt/60 }
      if enableFlights { paras["ef"] = true}
      if bookingSandbox { paras["bsb"] = true }
      if !twoWayHireCostIncludesReturn { paras["2wirc"] = false }
      paras["co2"] = emissions
      return paras
    }
  }
  
  @objc
  public static let parserJsonVersion: Int = 13
  
  @objc(defaultDictionary)
  public static func paras() -> [String: Any] {
    return Config().paras
  }
  
  private enum DefaultsKey: String {
    case sortIndex = "internalSortIndex"
    case ignoreCostToReturnCarHireVehicle = "profileTransportIgnoreCostToReturnCarHireVehicle"
  }
  
  @objc public static var sortOrder: STKTripCostType {
    get {
      let index = UserDefaults.shared.integer(forKey: DefaultsKey.sortIndex.rawValue)
      return STKTripCostType(rawValue: index) ?? .score
    }
    set {
      UserDefaults.shared.set(newValue.rawValue, forKey: DefaultsKey.sortIndex.rawValue)
    }
  }
  
  /// Determine whether two-way-hire vehicles, such as pod-based car-share, should ignore the cost of returning the car-hire vehicle to its pick-up location. By default this is set to `false` and the cost of returning the vehicle to its pick-up location will be added to all one-way trips. Set this to `true` if the cost of the trip should only include the cost that's attributed to this trip and ignore the unavoidable additional cost for returning the vehicle to its pick-up location.
  public static var ignoreCostToReturnCarHireVehicle: Bool {
    get {
      return UserDefaults.shared.bool(forKey: DefaultsKey.ignoreCostToReturnCarHireVehicle.rawValue)
    }
    set {
      UserDefaults.shared.set(newValue, forKey: DefaultsKey.ignoreCostToReturnCarHireVehicle.rawValue)
    }
  }
  
}

// MARK: - Equality

public func ==(lhs: TKSettings.Config.Speed, rhs: TKSettings.Config.Speed) -> Bool {
  switch (lhs, rhs) {
  case (.impaired, .impaired): return true
  case (.slow, .slow): return true
  case (.medium, .medium): return true
  case (.fast, .fast): return true
  case (.custom(let speed1), .custom(let speed2)): return fabs(speed1 - speed2) < 0.1
  default: return false
  }
}
extension TKSettings.Config.Speed: Equatable { }


// MARK: - API Values

extension TKSettings.Config.Speed {
  public var apiValue: Any {
    switch self {
    case .impaired:          return -1
    case .slow:              return 0
    case .medium:            return 1
    case .fast:              return 2
    case .custom(let speed): return "(\(speed)m/s"
    }
  }
  
  init?(apiValue: Any?) {
    if let int = apiValue as? Int {
      switch int {
      case -1: self = .impaired
      case 0: self = .slow
      case 1: self = .medium
      case 2: self = .fast
      default: return nil
      }
    }
    
    if let string = apiValue as? String,
      let speed = CLLocationSpeed(string.replacingOccurrences(of: "m/s", with: "")) {
      self = .custom(speed)
    } else {
      return nil
    }
  }
}

// MARK: - Codable

extension TKSettings {
  fileprivate enum DecodingError: Error {
    case unknownType(String)
  }
}

extension TKSettings.Config.Speed: Codable {
  private enum CodingKeys: String, CodingKey {
    case type
    case speed
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type: String = try container.decode(String.self, forKey: .type)
    switch type {
    case "impaired": self = .impaired
    case "slow": self = .slow
    case "medium": self = .medium
    case "fast": self = .fast
    case "custom": self = .custom(try container.decode(CLLocationSpeed.self, forKey: .speed))
    default: throw TKSettings.DecodingError.unknownType(type)
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .impaired:
      try container.encode("impaired", forKey: .type)
    case .slow:
      try container.encode("slow", forKey: .type)
    case .medium:
      try container.encode("medium", forKey: .type)
    case .fast:
      try container.encode("fast", forKey: .type)
    case .custom(let value):
      try container.encode("custom", forKey: .type)
      try container.encode(value, forKey: .speed)
    }
  }
}
