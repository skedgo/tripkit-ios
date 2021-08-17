//
//  TKUIRoutingResultsViewModel+ToggleModes.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.08.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKit

extension TKUIRoutingResultsViewModel {
  
  struct AvailableModes: Equatable {
    static let none = AvailableModes(available: [], enabled: [])
    
    let available: [TKRegion.RoutingMode]
    fileprivate let enabled: Set<String>
    
    func isEnabled(_ mode: TKRegion.RoutingMode) -> Bool {
      return enabled.contains(mode.identifier)
    }
  }
  
  private static func modes(for request: TripRequest) -> [TKRegion.RoutingMode] {
    let regions = [request.startRegion, request.endRegion, request.spanningRegion].compactMap { $0 }
    return TKRegionManager.sortedModes(in: regions)

  }
  
  static func buildAvailableModes(for request: TripRequest, mutable: Bool) -> AvailableModes? {
    let all = modes(for: request)
      
    let enabledModes: Set<String>
    if mutable {
      let enabled = TKUserProfileHelper.orderedEnabledModeIdentifiersForAvailableModeIdentifiers(all.map { $0.identifier })
      var newEnabled = Set(enabled)
      
      if TKUserProfileHelper.showWheelchairInformation {
        newEnabled.insert(TKTransportModeIdentifierWheelchair)
        newEnabled.remove(TKTransportModeIdentifierWalking)
      } else {
        newEnabled.insert(TKTransportModeIdentifierWalking)
        newEnabled.remove(TKTransportModeIdentifierWheelchair)
      }
      enabledModes = newEnabled
    
    } else {
      // Make sure we enable all the modes, to not hide any results
      enabledModes = request.trips.reduce(into: Set()) { $0.formUnion($1.usedModeIdentifiers) }
    }
    
    return AvailableModes(available: all, enabled: enabledModes)
  }
  
  static func updateAvailableModes(enabled: [String]?, request: TripRequest?) -> AvailableModes? {
    guard let enabled = enabled, let all = request.map(Self.modes(for:)) else { return nil }

    // check this first, in case that TKUserProfileHelper messes with it
    let oldWheelchairOn = TKUserProfileHelper.showWheelchairInformation

    // handle regular modes
    var hidden = all.map(\.identifier)
    hidden.removeAll(where: enabled.contains)
    TKUserProfileHelper.updateTransportModesWithEnabledOrder(nil, hidden: Set(hidden))
    
    // handle toggling wheelchair on and off
    let newWheelchairOn: Bool
    switch (enabled.contains(TKTransportModeIdentifierWheelchair), enabled.contains(TKTransportModeIdentifierWalking)) {
    case (true, true), (false, false): newWheelchairOn = !oldWheelchairOn
    case (true, false): newWheelchairOn = true
    case (false, true): newWheelchairOn = false
    }
    guard newWheelchairOn != oldWheelchairOn else {
      return nil // no need to update toggler
    }
    
    TKUserProfileHelper.showWheelchairInformation = newWheelchairOn

    var newEnabled = Set(enabled)
    if newWheelchairOn {
      newEnabled.insert(TKTransportModeIdentifierWheelchair)
      newEnabled.remove(TKTransportModeIdentifierWalking)
    } else {
      newEnabled.insert(TKTransportModeIdentifierWalking)
      newEnabled.remove(TKTransportModeIdentifierWheelchair)
    }
    return AvailableModes(available: all, enabled: newEnabled)
  }
  
}