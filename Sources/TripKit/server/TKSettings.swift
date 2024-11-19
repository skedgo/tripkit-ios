//
//  TKSettings.swift
//  TripKit
//
//  Created by Adrian Schoenig on 4/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

@objc
public class TKSettings: NSObject {
  
  private override init() {
    super.init()
  }
  
  public enum DefaultsKey: String {
    case sortIndex = "internalSortIndex"
    case includeCostToReturnCarHireVehicle = "profileTransportIncludeCostToReturnCarHireVehicle"
    case onWheelchair = "profileOnWheelchair"
    case sortedEnabled = "profileSortedModeIdentifiers"
    case hidden = "profileHiddenModeIdentifiers"
    case disliked = "profileDislikedTransitMode"
    case disabled = "profileDisabledSharedVehicleMode"
    case cyclingSpeed = "profileTransportCycleSpeed"
    case walkingSpeed = "profileTransportWalkSpeed"
    case minimumTransferTime = "profileTransportTransferTime"
    case maximumWalkDuration = "profileTransportWalkMaxDuration"
    case concessionPricing = "profileTransportConcessionPricing"
    case transportEmissions = "profileTransportEmissions"
    case timeToLeaveHeadway = "profileTimeToLeaveHeadway"
    
    case bookingsUseSandbox = "profileBookingsUseSandbox"
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
  
  /// The maximum walking duration is a per-segment limit for mixed results, i.e., it does not apply to walking-only trips.
  public static var maximumWalkingDuration: TimeInterval? {
    get {
      (UserDefaults.shared.object(forKey: DefaultsKey.maximumWalkDuration.rawValue) as? NSNumber)?.doubleValue
    }
    set {
      UserDefaults.shared.set(newValue, forKey: DefaultsKey.maximumWalkDuration.rawValue)
    }
  }
  
  /// Whether to show wheelchair information and show routes as being
  /// on a wheelchair. This will set TripKit's settings
  @objc
  public class var showWheelchairInformation: Bool {
    get { UserDefaults.shared.bool(forKey: DefaultsKey.onWheelchair.rawValue) }
    set { UserDefaults.shared.set(newValue, forKey: DefaultsKey.onWheelchair.rawValue) }
  }
  
  public class var useConcessionPricing: Bool {
    get { UserDefaults.shared.bool(forKey: DefaultsKey.concessionPricing.rawValue) }
    set { UserDefaults.shared.set(newValue, forKey: DefaultsKey.concessionPricing.rawValue) }
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
    case custom(TKAPI.Speed)
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
    case "custom": self = .custom(try container.decode(TKAPI.Speed.self, forKey: .speed))
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

// MARK: - Enabled transport modes

extension TKSettings {
  
  public static var hiddenModesPickedManually: Bool {
    get { UserDefaults.shared.object(forKey: DefaultsKey.hidden.rawValue) != nil }
  }

  /// Overwrites user preferences for each non-nil value.
  @objc
  public static func updateTransportModesWithEnabledOrder(_ enabled: [String]?, hidden: Set<String>?)
  {
    let shared = UserDefaults.shared
    if let enabled = enabled {
      shared.set(enabled, forKey: DefaultsKey.sortedEnabled.rawValue)
      if enabled.contains(TKTransportMode.wheelchair.modeIdentifier) {
        TKSettings.showWheelchairInformation = true
      } else if enabled.contains(TKTransportMode.walking.modeIdentifier) {
        TKSettings.showWheelchairInformation = false
      }
    }
    if let hidden = hidden {
      shared.set(Array(hidden), forKey: DefaultsKey.hidden.rawValue)
      if hidden.contains(TKTransportMode.wheelchair.modeIdentifier) {
        TKSettings.showWheelchairInformation = false
      }
    }
  }
  
  @objc
  public static func orderedEnabledModeIdentifiersForAvailableModeIdentifiers(_ available: [String]) -> [String] {
    let hidden = hiddenModeIdentifiers
    let ordered = available.filter { !hidden.contains($0) }
    
    // Once we let users sort them again, do something like this:
//    if let sorted = NSUserDefaults.sharedDefaults().objectForKey(DefaultsKey.SortedEnabled.rawValue) as? [Identifier] {
//      ordered.sortInPlace { sorted.indexOf($0) < sorted.indexOf($1) }
//    }
    
    return ordered
  }
  
  public static func enabledModeIdentifiers(_ available: [String]) -> Set<String> {
    let hidden = hiddenModeIdentifiers
    let ordered = available.filter { !hidden.contains($0) }
    return Set(ordered)
  }
  
  public static func modeIdentifierIsHidden(_ modeIdentifier: String) -> Bool {
    return hiddenModeIdentifiers.contains(modeIdentifier)
  }
  
  public static func setModeIdentifier(_ modeIdentifier: String, toHidden hidden: Bool) {
    update(hiddenModeIdentifiers, forKey: .hidden, modeIdentifier: modeIdentifier, include: hidden)
  }
  
  private static func update(_ identifiers: Set<String>, forKey key: DefaultsKey, modeIdentifier: String, include: Bool) {
    var modes = identifiers
    
    if include {
      modes.insert(modeIdentifier)
    } else {
      modes.remove(modeIdentifier)
    }
    
    UserDefaults.shared.set(Array(modes), forKey: key.rawValue)
  }
  
  public static internal(set) var hiddenModeIdentifiers: Set<String> {
    get {
      if let hidden = UserDefaults.shared.object(forKey: DefaultsKey.hidden.rawValue) as? [String] {
        return Set(hidden)
      } else {
        return [TKTransportMode.schoolBuses.modeIdentifier]
      }
    }
    set {
      if newValue.isEmpty {
        UserDefaults.shared.removeObject(forKey: DefaultsKey.hidden.rawValue)
      } else {
        UserDefaults.shared.set(Array(newValue), forKey: DefaultsKey.hidden.rawValue)
      }
    }
  }
  
}

// MARK: - Preferred/disliked public transit modes

extension TKSettings {
  
  public static func setTransitMode(_ identifier: String, asDisliked disliked: Bool) {
    var modes = dislikedTransitModes
    if disliked {
      modes.remove(identifier)
    } else {
      modes.insert(identifier)
    }
    self.dislikedTransitModes = modes
  }
  
  public static var dislikedTransitModes: Set<String> {
    get {
      if let disliked = UserDefaults.shared.object(forKey: DefaultsKey.disliked.rawValue) as? [String] {
        return Set(disliked)
      } else {
        return []
      }
    }
    set {
      if newValue.isEmpty {
        UserDefaults.shared.removeObject(forKey: DefaultsKey.disliked.rawValue)
      } else {
        UserDefaults.shared.set(Array(newValue), forKey: DefaultsKey.disliked.rawValue)
      }
    }
  }
  
}

// MARK: - Mode by mode, Mode picker

extension TKSettings {
  
  public class func update(pickedModes: Set<TKModeInfo>, allModes: Set<TKModeInfo>) {
    var modes = Set(disabledSharedVehicleModes)
    
    let picked = Set(pickedModes.compactMap { try? JSONEncoder().encode($0)  })
    var toDisable = Set(allModes.compactMap { try? JSONEncoder().encode($0)  })
    
    toDisable.subtract(picked)
    
    modes.subtract(picked)
    modes.formUnion(toDisable)
    
    UserDefaults.shared.set(Array(modes), forKey: DefaultsKey.disabled.rawValue)
  }
  
  class var disabledSharedVehicleModes: [Data] {
    if let disabled = UserDefaults.shared.object(forKey: DefaultsKey.disabled.rawValue) as? [Data] {
      return disabled
    } else {
      return []
    }
  }
}

// MARK: - Emissions

extension TKSettings {
  
  /// - Parameters:
  ///   - gramsCO2PerKm: Emissions for supplied mode identifier in grams of CO2 per kilometre
  ///   - modeIdentifier: Mode identifier for which to apply these emissions
  public class func setEmissions(gramsCO2PerKm: Double, modeIdentifier: String) {
    var updated = transportEmissions
    updated[modeIdentifier] = gramsCO2PerKm
    UserDefaults.shared.set(updated, forKey: DefaultsKey.transportEmissions.rawValue)
  }
  
  public class func clearEmissions() {
    UserDefaults.shared.removeObject(forKey: DefaultsKey.transportEmissions.rawValue)
  }
  
  public class var transportEmissions: [String: Double] {
    (UserDefaults.shared.object(forKey: DefaultsKey.transportEmissions.rawValue) as? [String: Double]) ?? [:]
  }
  
}

// MARK: - Notifications

extension TKSettings {
  
  /// The minutes before a trip's start that the "Time to leave" notification should fire. Defaults to 15 (minutes)
  public static var notificationTimeToLeaveHeadway: Int {
    get {
      (UserDefaults.shared.object(forKey: DefaultsKey.timeToLeaveHeadway.rawValue) as? NSNumber)?.intValue ?? 15
    }
    set {
      UserDefaults.shared.set(newValue, forKey: DefaultsKey.timeToLeaveHeadway.rawValue)
    }
  }
  
}
