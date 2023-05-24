//
//  TKSettings+Config.swift
//  TripKit-iOS
//
//  Created by Adrian Schönig on 24.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKSettings {
  public struct Config: Equatable {
    public enum DistanceUnit: String, Codable {
      case auto
      case metric
      case imperial
    }
    
    public struct Weights: Codable, Equatable {
      var money: Double = 1.0
      var carbon: Double = 1.0
      var time: Double = 1.0
      var hassle: Double = 1.0
      var exercise: Double = 1.0
    }
    
    public let version: Int = TKSettings.parserJsonVersion
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

    public static func userSettings() -> Self {
      return .init(fromDefaults: true)
    }
    
    public static func defaultValues() -> Self {
      return .init(fromDefaults: false)
    }
    
    @available(*, deprecated, message: "Use TKSettings.Config.userSettings() or TKSettings.Config.defaultValues()")
    public init() {
      self.init(fromDefaults: true)
    }
    
    private init(fromDefaults: Bool) {
      if fromDefaults {
        distanceUnit = Locale.current.usesMetricSystem ? .metric : .imperial
        weights = .init(
          money: TKSettings[.money],
          carbon: TKSettings[.carbon],
          time: TKSettings[.time],
          hassle: TKSettings[.hassle],
          exercise: TKSettings[.exercise]
        )
        avoidModes = Array(TKSettings.dislikedTransitModes)
        concession = TKSettings.useConcessionPricing
        wheelchair = TKSettings.showWheelchairInformation
        twoWayHireCostIncludesReturn = TKSettings.includeCostToReturnCarHireVehicle
        
        cyclingSpeed = TKSettings.cyclingSpeed
        walkingSpeed = TKSettings.walkingSpeed

        if let duration = TKSettings.maximumWalkingDuration {
          maximumWalkingMinutes = duration / 60
        }

        minimumTransferMinutes = TKSettings.minimumTransferMinutes

        emissions = TKSettings.transportEmissions
        
#if DEBUG
        if let setting = UserDefaults.shared.object(forKey: TKSettings.DefaultsKey.bookingsUseSandbox.rawValue) as? NSNumber {
          bookingSandbox = setting.boolValue
        } else {
          bookingSandbox = true // Default to sandbox while developing
        }
#else
        if UserDefaults.shared.bool(forKey: TKSettings.DefaultsKey.bookingsUseSandbox.rawValue) {
          bookingSandbox = true
        }
#endif
      
      } else {
        weights = .init()
      }
    }
    
    public var paras: [String: Any] {
      var paras: [String: Any] = [
        "v": version,
        "wp": "(\(weights[.money]),\(weights[.carbon]),\(weights[.time]),\(weights[.hassle]))",
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
  }
  
  public static let parserJsonVersion: Int = 13
  
  @available(*, deprecated, message: "Use TKSettings.Config.userSettings().paras directly instead")
  public static var config: [String: Any] {
    return Config.userSettings().paras
  }

}

extension TKSettings.Config: Codable {
  
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

extension TKSettings.Config.Weights {
  public subscript(weight: TKSettings.Weight) -> Double {
    switch weight {
    case .money: return money
    case .carbon: return carbon
    case .time: return time
    case .hassle: return hassle
    case .exercise: return exercise
    }
  }
}
