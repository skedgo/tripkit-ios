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
    
    public let version: Int = TKSettings.parserJsonVersion
    public var distanceUnit: DistanceUnit = .auto
    public var weights: [Weight: Double]
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
        let shared = UserDefaults.shared
        distanceUnit = Locale.current.usesMetricSystem ? .metric : .imperial
        weights = Dictionary(uniqueKeysWithValues: Weight.allCases.map {
          ($0, TKSettings[$0])
        })
        avoidModes = Array(TKSettings.dislikedTransitModes)
        concession = TKSettings.useConcessionPricing
        wheelchair = TKSettings.showWheelchairInformation
        twoWayHireCostIncludesReturn = TKSettings.includeCostToReturnCarHireVehicle
        
        cyclingSpeed = TKSettings.cyclingSpeed
        walkingSpeed = TKSettings.walkingSpeed

        if let minutes = shared.object(forKey: TKDefaultsKeyProfileTransportWalkMaxDuration) as? NSNumber {
          maximumWalkingMinutes = minutes.doubleValue
        }

        minimumTransferMinutes = TKSettings.minimumTransferTime

        emissions = (shared.object(forKey: TKDefaultsKeyProfileTransportEmissions) as? [String: Double]) ?? [:]
        
        #if DEBUG
        if let setting = shared.object(forKey: TKDefaultsKeyProfileBookingsUseSandbox) as? NSNumber {
          bookingSandbox = setting.boolValue
        } else {
          bookingSandbox = true // Default to sandbox while developing
        }
        #else
        if shared.bool(forKey: TKDefaultsKeyProfileBookingsUseSandbox) {
          bookingSandbox = true
        }
        #endif
      
      } else {
        weights = Dictionary(uniqueKeysWithValues: Weight.allCases.map {
          ($0, 1)
        })
      }
    }
    
    public var paras: [String: Any] {
      var paras: [String: Any] = [
        "v": version,
        "wp": "(\(weights[.money] ?? 1.0),\(weights[.carbon] ?? 1.0),\(weights[.time] ?? 1.0),\(weights[.hassle] ?? 1.0))",
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

