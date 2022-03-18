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
    public let weights: [Weight: Double]
    public let avoidModes: [String]
    public let concession: Bool
    public let wheelchair: Bool
    public let cyclingSpeed: Speed
    public let walkingSpeed: Speed
    public let maximumWalkingMinutes: Double?
    public let minimumTransferMinutes: Double?
    public let emissions: [String: Double]
    public let bookingSandbox: Bool
    public let twoWayHireCostIncludesReturn: Bool

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
      } else {
        maximumWalkingMinutes = nil
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

