//
//  TKSettings.swift
//  TripKit
//
//  Created by Adrian Schoenig on 4/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension TKSettings {
  
  public enum DefaultsKey: String {
    case sortIndex = "internalSortIndex"
    case includeCostToReturnCarHireVehicle = "profileTransportIncludeCostToReturnCarHireVehicle"
    case onWheelchair = "profileOnWheelchair"
    case sortedEnabled = "profileSortedModeIdentifiers"
    case hidden = "profileHiddenModeIdentifiers"
    case disliked = "profileDislikedTransitMode"
    case cyclingSpeed = "profileTransportCycleSpeed"
    case walkingSpeed = "profileTransportWalkSpeed"
    case minimumTransferTime = "profileTransportTransferTime"
  }
  
  public static var sortOrder: TKTripCostType {
    get {
      let index = UserDefaults.shared.integer(forKey: DefaultsKey.sortIndex.rawValue)
      return TKTripCostType(rawValue: index) ?? .score
    }
    set {
      UserDefaults.shared.set(newValue.rawValue, forKey: DefaultsKey.sortIndex.rawValue)
    }
  }
  
  public static var minimumTransferTime: TimeInterval? {
    get {
      (UserDefaults.shared.object(forKey: DefaultsKey.minimumTransferTime.rawValue) as? NSNumber)?.doubleValue
    }
    set {
      UserDefaults.shared.set(newValue, forKey: DefaultsKey.minimumTransferTime.rawValue)
    }
  }
  
  ///  The minimum transfer duration applies for trips with more than one public transport segment. It sets the minimum time that the user needs to arrive at every public transport segment after the first one.
  ///  In minutes, rounded up.
  public static var minimumTransferMinutes: Double? {
    get {
      minimumTransferTime.map { ceil($0 / 60) }
    }
    set {
      minimumTransferTime = newValue.map { $0  * 60 }
    }
  }
  
  /// Determine whether two-way-hire vehicles, such as pod-based car-share, should include the cost of returning the car-hire vehicle to its pick-up location. By default this is set to `false` and the cost of the trip only include the cost that's attributed to this trip and ignore the unavoidable additional cost for returning the vehicle to its pick-up location. Set this to `true` if the cost of returning the vehicle to its pick-up location should be added to all one-way trips.
  public static var includeCostToReturnCarHireVehicle: Bool {
    get {
      return UserDefaults.shared.bool(forKey: DefaultsKey.includeCostToReturnCarHireVehicle.rawValue)
    }
    set {
      UserDefaults.shared.set(newValue, forKey: DefaultsKey.includeCostToReturnCarHireVehicle.rawValue)
    }
  }
  
}

extension TKSettings {
  fileprivate enum DecodingError: Error {
    case unknownType(String)
  }
}

// MARK: - Weights

extension TKSettings {
  public enum Weight: String, Codable, CaseIterable {
    case money
    case carbon
    case time
    case hassle
    case exercise
  }
  
  public static subscript(weight: TKSettings.Weight) -> Double {
    get {
      (UserDefaults.shared.object(forKey: weight.defaultsKey) as? NSNumber)?.doubleValue ?? 1.0
    }
    set {
      let pruned = max(0.1, min(2.0, newValue))
      UserDefaults.shared.set(pruned, forKey: weight.defaultsKey)
    }
  }
}

public extension TKSettings.Weight {
  var defaultsKey: String {
    switch self {
    case .money: return "weightMoney"
    case .carbon: return "weightCarbon"
    case .time: return "weightTime"
    case .hassle: return "weightHassle"
    case .exercise: return "weightExercise"
    }
  }
}

// MARK: - Speeds

extension TKSettings {
  public enum Speed: Equatable {
    case impaired
    case slow
    case medium
    case fast
    case custom(CLLocationSpeed)
  }
  
  /// The cycling speed. Slow is roughly 8km/h, average 12km/h, fast 25km/h.
  public static var cyclingSpeed: Speed {
    get {
      Speed(apiValue: UserDefaults.shared.object(forKey: DefaultsKey.cyclingSpeed.rawValue)) ?? .medium
    }
    set {
      UserDefaults.shared.set(newValue.apiValue, forKey: DefaultsKey.cyclingSpeed.rawValue)
    }
  }
  
  /// The walking speed. Slow is roughly 2km/h, average 4km/h, fast 6km/h.
  public static var walkingSpeed: Speed {
    get {
      Speed(apiValue: UserDefaults.shared.object(forKey: DefaultsKey.walkingSpeed.rawValue)) ?? .medium
    }
    set {
      UserDefaults.shared.set(newValue.apiValue, forKey: DefaultsKey.walkingSpeed.rawValue)
    }
  }

}

extension TKSettings.Speed: Codable {
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

extension TKSettings.Speed {
  public var apiValue: Any {
    switch self {
    case .impaired:          return -1
    case .slow:              return 0
    case .medium:            return 1
    case .fast:              return 2
    case .custom(let speed): return "(\(speed)m/s"
    }
  }
  
  public init?(apiValue: Any?) {
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
