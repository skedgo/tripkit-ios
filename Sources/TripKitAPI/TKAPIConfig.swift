//
//  TKSettings+Config.swift
//  TripKit-iOS
//
//  Created by Adrian Schönig on 24.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public struct TKAPIConfig: Equatable {
  public static let parserJsonVersion: Int = 13

  public enum DistanceUnit: String, Codable {
    case auto
    case metric
    case imperial
  }
  
  public struct Weights: Codable, Equatable {
    public var money: Double = 1.0
    public var carbon: Double = 1.0
    public var time: Double = 1.0
    public var hassle: Double = 1.0
    public var exercise: Double = 1.0
  }
  
  public enum Speed: Equatable {
    case impaired
    case slow
    case medium
    case fast
    case custom(TKAPI.Speed)
  }
  
  public let version: Int = TKAPIConfig.parserJsonVersion
  public var distanceUnit: DistanceUnit = .auto
  public var weights: Weights
  public var avoidModes: [String] = []
  public var concession: Bool = false
  public var wheelchair: Bool = false
  public var cyclingSpeed: Speed = .medium
  public var walkingSpeed: Speed = .medium
  public var maximumWalkingMinutes: Double? = nil
  public var minimumTransferMinutes: Double? = nil
  public var emissions: [String: Double] = [:]
  public var bookingSandbox: Bool = false
  public var twoWayHireCostIncludesReturn: Bool = false
  
  public static func defaultValues() -> Self {
    return .init()
  }
  
  private init() {
    self.weights = .init()
  }
  
  public var paras: [String: Any] {
    var paras: [String: Any] = [
      "v": version,
      "wp": "(\(weights.money),\(weights.carbon),\(weights.time),\(weights.hassle))",
    ]
    if twoWayHireCostIncludesReturn { paras["2wirc"] = twoWayHireCostIncludesReturn }
    if distanceUnit != .auto { paras["unit"] = distanceUnit.rawValue }
    if cyclingSpeed != .medium { paras["cs"] = cyclingSpeed.apiValue }
    if walkingSpeed != .medium { paras["ws"] = walkingSpeed.apiValue }
    if !avoidModes.isEmpty { paras["avoid"] = avoidModes }
    if concession { paras["conc"] = true }
    if wheelchair { paras["wheelchair"] = true }
    if let wm = maximumWalkingMinutes { paras["wm"] = wm }
    if let tt = minimumTransferMinutes { paras["tt"] = tt }
    if bookingSandbox { paras["bsb"] = true }
    paras["co2"] = emissions.isEmpty ? nil : emissions
    return paras
  }

  fileprivate enum DecodingError: Error {
    case unknownType(String)
  }
}

extension TKAPIConfig: Codable {
  
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
  
}

extension TKAPIConfig.Speed: Codable {
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
    case "custom": self = .custom(try container.decode(TKAPI.Speed.self, forKey: .speed))
    default: throw TKAPIConfig.DecodingError.unknownType(type)
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

extension TKAPIConfig.Speed {
  public var apiValue: Any {
    switch self {
    case .impaired:          return -1
    case .slow:              return 0
    case .medium:            return 1
    case .fast:              return 2
    case .custom(let speed):
      let formatter = NumberFormatter()
      formatter.locale = Locale(identifier: "en_US")
      formatter.maximumFractionDigits = 2
      return "\(formatter.string(from: .init(value: speed))!)mps"
    }
  }
  
  public init?(apiValue: Any?) {
    if let int = apiValue as? Int {
      switch int {
      case -1: self = .impaired; return
      case 0: self = .slow; return
      case 1: self = .medium; return
      case 2: self = .fast; return
      default: return nil
      }
    }
    
    if let string = apiValue as? String,
      let speed = TKAPI.Speed(string.replacingOccurrences(of: "mps", with: "")) {
      self = .custom(speed)
    } else {
      return nil
    }
  }
}
