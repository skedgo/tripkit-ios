//
//  TKTransportMode.swift
//  TripKit
//
//  Created by Adrian Schönig on 17/10/2022.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

import Foundation


@available(*, unavailable, renamed: "TKTransportMode")
public typealias TKTransportModes = TKTransportMode

public enum TKTransportMode: String, CaseIterable {
  
  case flight = "in_air"
  case publicTransport = "pt_pub"
  case limited = "pt_ltd"
  case schoolBuses = "pt_ltd_SCHOOLBUS"
  case drt = "ps_drt"
  case taxi = "ps_tax"
  case tnc = "ps_tnc"
  case autoRickshaw = "ps_ars"
  case car = "me_car"
  case carShare = "me_car-s"
  case carRental = "me_car-r"
  case carPool = "me_car-p"
  case motorbike = "me_mot"
  case micromobility = "me_mic"
  case bicycle  = "me_mic_bic"
  case micromobilityShared = "me_mic-s"
  case bicycleShared = "me_mic-s_bic"
  case walking = "wa_wal"
  case wheelchair = "wa_whe"

  case bicycleDeprecated = "cy_bic"
  case bikeShareDeprecated = "cy_bic-s"
  
  public var modeIdentifier: String {
    rawValue
  }
  
  /// - Returns: mode-related part of the image name
  static func modeImageName(forModeIdentifier identifier: String) -> String? {
    switch TKTransportMode(modeIdentifier: identifier) {
    case .flight:
      return "aeroplane"
    case .publicTransport, .schoolBuses:
      return "public-transport"
    case .limited:
      return "bus"
    case .drt:
      return "shuttlebus"
    case .bicycle, .bicycleDeprecated, .micromobility:
      return "bicycle"
    case .bicycleShared, .bikeShareDeprecated:
      return "bicycle-share"
    case .micromobilityShared:
      return "micromobility-share"
    case .car:
      return "car"
    case .carPool:
      return "car-pool"
    case .carShare, .carRental:
      return "car-share"
    case .taxi:
      return "taxi"
    case .tnc:
      return "car-ride-share"
    case .autoRickshaw:
      return "auto-rickshaw"
    case .motorbike:
      return "motorbike"
    case .walking:
      return "walk"
    case .wheelchair:
      return "wheelchair"
    case .none:
      switch identifier.components(separatedBy: "_").first {
      case "pt":
        return "public-transport"
      case "me":
        return "car"
      case "cy":
        return "bicycle"
      case "wa":
        return "walk"
      case "in":
        return "aeroplane"
      default:
        return nil // probably a stationary ID
      }
    }
  }
  
  
  /// - Returns: The generic mode identifier part, e.g., `pt_pub` for `pt_pub_bus`, which can be used as routing input
  static func genericModeIdentifier(forModeIdentifier identifier: String) -> String {
    identifier
      .components(separatedBy: "_")
      .prefix(2)
      .joined(separator: "_")
  }
  
  public static func modeIdentifierIsPublicTransport(_ identifier: String) -> Bool {
    identifier.hasPrefix("pt_")
  }
  
  public static func modeIdentifierIsWalking(_ identifier: String) -> Bool {
    identifier.hasPrefix("wa_")
  }
  
  public static func modeIdentifierIsWheelchair(_ identifier: String) -> Bool {
    TKTransportMode(rawValue: identifier) == .wheelchair
  }
  
  public static func modeIdentifierIsCycling(_ identifier: String) -> Bool {
    switch TKTransportMode(modeIdentifier: identifier) {
    case .micromobilityShared, .micromobility, .bicycleShared, .bicycle, .bikeShareDeprecated, .bicycleDeprecated:
      return true
    default:
      return false
    }
  }
  
  static func modeIdentifierIsDriving(_ identifier: String) -> Bool {
    switch TKTransportMode(modeIdentifier: identifier) {
    case .car, .carShare, .carRental, .carPool, .motorbike:
      return true
    default:
      return false
    }
  }
  
  static func modeIdentifierIsSharedVehicle(_ identifier: String) -> Bool {
    switch TKTransportMode(modeIdentifier: identifier) {
    case .carShare, .bicycleShared, .micromobilityShared, .bikeShareDeprecated:
      return true
    default:
      return false
    }
  }
  
  static func modeIdentifierIsAffectedByTraffic(_ identifier: String) -> Bool {
    identifier.hasPrefix("me_") || identifier.hasPrefix("ps_")
  }
  
  static func modeIdentifierIsFlight(_ identifier: String) -> Bool {
    TKTransportMode(modeIdentifier: identifier) == .flight
  }
  
  static func modeIdentifierIsExpensive(_ identifier: String) -> Bool {
    switch TKTransportMode(modeIdentifier: identifier) {
    case .carShare, .carRental, .flight, .taxi, .tnc:
      return true
    default:
      return false
    }
  }
  
}

extension TKTransportMode {
  init?(modeIdentifier: String) {
    if let exact = TKTransportMode(rawValue: modeIdentifier) {
      self = exact
    } else if let prefix = TKTransportMode.allCases.first(where: { $0.modeIdentifier.hasPrefix(modeIdentifier) }) {
      self = prefix
    } else {
      return nil
    }
  }
}

public extension TKTransportMode {
  static func color(for modeIdentifier: String) -> TKColor {
    
    switch modeIdentifier {
    case "in_air",
         "pt_pub_airport":    return #colorLiteral(red: 0.2317194939, green: 0.6177652478, blue: 0.553303957, alpha: 1)
    case "pt_pub_bus":        return #colorLiteral(red: 0, green: 0.7074869275, blue: 0.3893686533, alpha: 1)
    case "pt_pub_coach":      return #colorLiteral(red: 0.3531380296, green: 0.6268352866, blue: 1, alpha: 1)
    case "pt_pub_train":      return #colorLiteral(red: 0.4003433585, green: 0.3975370526, blue: 0.7013071179, alpha: 1)
    case "pt_pub_subway":     return #colorLiteral(red: 0.6026608944, green: 0.3418461382, blue: 0.614194572, alpha: 1)
    case "pt_pub_tram":       return #colorLiteral(red: 0.9155990481, green: 0.6139323115, blue: 0.2793464363, alpha: 1)
    case "pt_pub_ferry":      return #colorLiteral(red: 0.3049013913, green: 0.617303133, blue: 0.8455126882, alpha: 1)
    case "pt_pub_cablecar":   return #colorLiteral(red: 0.8532444835, green: 0.3551393449, blue: 0.2957291603, alpha: 1)
    case "pt_pub_funicular":  return #colorLiteral(red: 0.4494780302, green: 0.664527297, blue: 0.954687655, alpha: 1)
    case "pt_pub_monorail":   return #colorLiteral(red: 0.8918713927, green: 0.7548664212, blue: 0.08011957258, alpha: 1)
    case "ps_tax":            return #colorLiteral(red: 0.892275691, green: 0.8211820722, blue: 0.07182558626, alpha: 1)
    case "me_car":            return #colorLiteral(red: 0.2567383349, green: 0.5468673706, blue: 0.9439687133, alpha: 1)
    case "me_car-s":          return #colorLiteral(red: 0.4492250085, green: 0.6646941304, blue: 0.9505276084, alpha: 1)
    case "me_mic_bic":        return #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
    case "wa_wal":            return #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1)

//    case "bicycle-share"?: return #colorLiteral(red: 0.5058823529, green: 0.5019607843, blue: 0.7333333333, alpha: 1)
//    case "car-share"?:     return #colorLiteral(red: 0.5058823529, green: 0.5019607843, blue: 0.7333333333, alpha: 1)
//    case "parking"?:     return #colorLiteral(red: 0.5058823529, green: 0.5019607843, blue: 0.7333333333, alpha: 1)
//    case "taxi"?:     return #colorLiteral(red: 0.5058823529, green: 0.5019607843, blue: 0.7333333333, alpha: 1)

    default:
      if modeIdentifier.starts(with: "stationary_") {
        return #colorLiteral(red: 0.2567383349, green: 0.5468673706, blue: 0.9439687133, alpha: 1)
      } else {
        print("Default colour missing for: \(String(describing: modeIdentifier))")
        return TKStyleManager.globalTintColor()
      }
    }

  }
  
  /// Image that stands for the specified transport mode identifier
  static func title(for modeIdentifier: String) -> String? {
    if let known = TKRegionManager.shared.title(forModeIdentifier: modeIdentifier) {
      return known
    } else {
      switch modeIdentifier {
      case "in_air",
           "pt_pub_airport":    return "Plane"
      case "pt_pub_bus":        return "Bus"
      case "pt_pub_coach":      return "Coach"
      case "pt_pub_train":      return "Train"
      case "pt_pub_subway":     return "Subway"
      case "pt_pub_tram":       return "Tram"
      case "pt_pub_ferry":      return "Ferry"
      case "pt_pub_cablecar":   return "Cable car"
      case "pt_pub_funicular":  return "Funicular"
      case "pt_pub_monorail":   return "Monorail"
      case "ps_tax":            return "Taxi"
      case "me_car":            return Loc.VehicleTypeCar
      case "me_car-s":          return "Car-share"
      case "me_mot":            return Loc.VehicleTypeMotorbike
      case "me_mic_bic":        return Loc.VehicleTypeBicycle
      case "wa_wal":            return "Walking"
      default: return nil
      }
    }

  }
  
  static func image(for modeIdentifier: String) -> TKImage? {
    guard let part = self.modeImageName(forModeIdentifier: modeIdentifier) else { return nil }
    return TKStyleManager.image(named: "icon-mode-\(part)")
  }
}
