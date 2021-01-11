//
//  TKSettings+Config.swift
//  TripKit-iOS
//
//  Created by Adrian Schönig on 24.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
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
    public let maximumWalkingMinutes: Double?
    public let minimumTransferMinutes: Double?
    public let emissions: [String: Float]
    public let bookingSandbox: Bool
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
      case maximumWalkingMinutes = "wm"
      case minimumTransferMinutes = "tt"
      case emissions = "co2"
      case bookingSandbox = "bsb"
      case twoWayHireCostIncludesReturn = "2wirc"
    }
    
    public init() {
      let shared = UserDefaults.shared
      version = TKSettings.parserJsonVersion
      distanceUnit = Locale.current.usesMetricSystem ? .metric : .imperial
      weights = [
        .money:    (shared.object(forKey: TKDefaultsKeyProfileWeightMoney)    as? NSNumber)?.floatValue ?? 1.0,
        .carbon:   (shared.object(forKey: TKDefaultsKeyProfileWeightCarbon)   as? NSNumber)?.floatValue ?? 1.0,
        .time:     (shared.object(forKey: TKDefaultsKeyProfileWeightTime)     as? NSNumber)?.floatValue ?? 1.0,
        .hassle:   (shared.object(forKey: TKDefaultsKeyProfileWeightHassle)   as? NSNumber)?.floatValue ?? 1.0,
        .exercise: (shared.object(forKey: TKDefaultsKeyProfileWeightExercise) as? NSNumber)?.floatValue ?? 1.0,
      ]
      avoidModes = TKUserProfileHelper.dislikedTransitModes
      concession = shared.bool(forKey: TKDefaultsKeyProfileTransportConcessionPricing)
      wheelchair = TKUserProfileHelper.showWheelchairInformation
      twoWayHireCostIncludesReturn = TKSettings.includeCostToReturnCarHireVehicle
      
      cyclingSpeed = Speed(apiValue: shared.object(forKey: TKDefaultsKeyProfileTransportCyclingSpeed)) ?? .medium
      walkingSpeed = Speed(apiValue: shared.object(forKey: TKDefaultsKeyProfileTransportWalkSpeed)) ?? .medium

      if let minutes = shared.object(forKey: TKDefaultsKeyProfileTransportWalkMaxDuration) as? NSNumber {
        maximumWalkingMinutes = minutes.doubleValue
      } else {
        maximumWalkingMinutes = nil
      }

      if let minutes = shared.object(forKey: TKDefaultsKeyProfileTransportTransferTime) as? NSNumber {
        minimumTransferMinutes = minutes.doubleValue
      } else {
        minimumTransferMinutes = nil
      }

      emissions = (shared.object(forKey: TKDefaultsKeyProfileTransportEmissions) as? [String: Float]) ?? [:]
      
      #if DEBUG
      if let setting = shared.object(forKey: TKDefaultsKeyProfileBookingsUseSandbox) as? NSNumber {
        bookingSandbox = setting.boolValue
      } else {
        bookingSandbox = true // Default to sandbox while developing
      }
      #else
      if TKBetaHelper.isBeta(), shared.bool(forKey: TKDefaultsKeyProfileBookingsUseSandbox) {
        bookingSandbox = true
      } else {
        bookingSandbox = false
      }
      #endif
    }
    
    public var paras: [String: Any] {
      var paras: [String: Any] = [
        "v": version,
        "unit": distanceUnit.rawValue,
        "wp": "(\(weights[.money] ?? 1.0),\(weights[.carbon] ?? 1.0),\(weights[.time] ?? 1.0),\(weights[.hassle] ?? 1.0))",
        "cs": cyclingSpeed.apiValue,
        "ws": walkingSpeed.apiValue,
        "2wirc": twoWayHireCostIncludesReturn
      ]
      if !avoidModes.isEmpty { paras["avoid"] = avoidModes }
      if concession { paras["conc"] = true }
      if wheelchair { paras["wheelchair"] = true }
      if let wm = maximumWalkingMinutes { paras["wm"] = wm }
      if let tt = minimumTransferMinutes { paras["tt"] = tt }
      if bookingSandbox { paras["bsb"] = true }
      paras["co2"] = emissions.isEmpty ? nil : emissions
      return paras
    }
  }
  
  @objc
  public static let parserJsonVersion: Int = 13
  
  @objc
  @available(*, unavailable, renamed: "config")
  public static func defaultDictionary() -> [String: Any] {
    return config
  }
  
  @objc
  public static var config: [String: Any] {
    return Config().paras
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
