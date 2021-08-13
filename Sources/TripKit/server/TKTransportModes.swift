//
//  TKTransportModes.swift
//  TripKit
//
//  Created by Adrian Schönig on 26/4/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

#if SWIFT_PACKAGE
import TripKitObjc
#endif

public extension TKTransportModes {
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
}
