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
  
  /// - Returns: The generic mode identifier part, e.g., `pt_pub` for `pt_pub_bus`, which can be used as routing input
  public static func genericModeIdentifier(forModeIdentifier identifier: String) -> String {
    identifier
      .components(separatedBy: "_")
      .prefix(2)
      .joined(separator: "_")
  }
  
}

extension TKTransportMode {
  public init?(modeIdentifier: String) {
    if let exact = TKTransportMode(rawValue: modeIdentifier) {
      self = exact
    } else if let prefix = TKTransportMode.allCases.last(where: { modeIdentifier.hasPrefix($0.modeIdentifier) }) {
      self = prefix
    } else {
      return nil
    }
  }
}

