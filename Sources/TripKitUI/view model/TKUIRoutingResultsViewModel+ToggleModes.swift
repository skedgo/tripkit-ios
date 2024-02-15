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
      let enabled = TKSettings.orderedEnabledModeIdentifiersForAvailableModeIdentifiers(all.map { $0.identifier })
      var newEnabled = Set(enabled)
      
      if TKSettings.showWheelchairInformation {
        newEnabled.insert(TKTransportMode.wheelchair.modeIdentifier)
        newEnabled.remove(TKTransportMode.walking.modeIdentifier)
      } else {
        newEnabled.insert(TKTransportMode.walking.modeIdentifier)
        newEnabled.remove(TKTransportMode.wheelchair.modeIdentifier)
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

    // check this first, in case that TKSettings messes with it
    let oldWheelchairOn = TKSettings.showWheelchairInformation

    // handle toggling wheelchair on and off
    let newWheelchairOn: Bool
    switch (enabled.contains(TKTransportMode.wheelchair.modeIdentifier), enabled.contains(TKTransportMode.walking.modeIdentifier)) {
    case (true, true), (false, false): newWheelchairOn = !oldWheelchairOn
    case (true, false): newWheelchairOn = true
    case (false, true): newWheelchairOn = false
    }
    guard newWheelchairOn != oldWheelchairOn else {
      // handle regular modes
      var hidden = all.map(\.identifier)
      hidden.removeAll(where: enabled.contains)
      TKSettings.updateTransportModesWithEnabledOrder(nil, hidden: Set(hidden))
      
      // no changes in wheelchair preference, so just return the
      // existing `enabled`.
      return AvailableModes(available: all, enabled: Set(enabled))
    }
    
    TKSettings.showWheelchairInformation = newWheelchairOn

    var newEnabled = Set(enabled)
    if newWheelchairOn {
      newEnabled.insert(TKTransportMode.wheelchair.modeIdentifier)
      newEnabled.remove(TKTransportMode.walking.modeIdentifier)
      
      // Also disable modes unlikely to use on wheelchair/pram
      // Cycling, micromobility, and motorbike
      newEnabled.remove(TKTransportMode.bicycle.modeIdentifier)
      newEnabled.remove(TKTransportMode.bicycleShared.modeIdentifier)
      newEnabled.remove(TKTransportMode.bicycleDeprecated.modeIdentifier)
      newEnabled.remove(TKTransportMode.bikeShareDeprecated.modeIdentifier)
      newEnabled.remove(TKTransportMode.motorbike.modeIdentifier)
      newEnabled.remove(TKTransportMode.micromobility.modeIdentifier)
      newEnabled.remove(TKTransportMode.micromobilityShared.modeIdentifier)
    } else {
      newEnabled.insert(TKTransportMode.walking.modeIdentifier)
      newEnabled.remove(TKTransportMode.wheelchair.modeIdentifier)
    }
    
    var hidden = all.map(\.identifier)
    hidden.removeAll(where: newEnabled.contains)
    TKSettings.updateTransportModesWithEnabledOrder(nil, hidden: Set(hidden))
    
    return AvailableModes(available: all, enabled: newEnabled)
  }
  
}
