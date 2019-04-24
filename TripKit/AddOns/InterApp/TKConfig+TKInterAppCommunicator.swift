//
//  TKConfig+TKInterAppCommunicator.swift
//  TripKitInterApp-iOS
//
//  Created by Adrian Schönig on 23.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKit

extension TKConfig {
  
  public var interAppConfiguration: [String: Any] {
    return configuration["TKInterAppCommunicator"] as? [String: Any] ?? [:]
  }
  
  @objc
  public var googleMapsCallback: String? {
    return interAppConfiguration["googleMapsCallback"] as? String
  }
  
}
