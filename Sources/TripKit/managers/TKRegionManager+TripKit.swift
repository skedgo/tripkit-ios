//
//  TKRegionManager.swift
//  TripKit
//
//  Created by Adrian Schoenig on 26.09.17.
//
//

import Foundation

extension TKRegionManager {
  func remoteImageName(forModeIdentifier mode: String) -> String? {
    return response?.modes?[mode]?.icon
  }
  
  public func remoteImageIsTemplate(forModeIdentifier mode: String) -> Bool {
    return response?.modes?[mode]?.isTemplate ?? false
  }
  
  public func remoteImageIsBranding(forModeIdentifier mode: String) -> Bool {
    return response?.modes?[mode]?.isBranding ?? false
  }

  public func imageURL(forModeIdentifier mode: String?, iconType: TKStyleModeIconType) -> URL? {
    guard
      let mode = mode,
      let details = response?.modes?[mode]
      else { return nil }
    
    var part: String?
    switch iconType {
    case .mapIcon, .listMainMode, .resolutionIndependent:
      part = details.icon
    case .vehicle:
      part = details.vehicleIcon
    case .alert:
      part = nil // not supported for modes
    @unknown default:
      part = nil
    }
    guard let fileNamePart = part else { return nil }
    return TKServer.imageURL(iconFileNamePart: fileNamePart, iconType: iconType)
  }  
}

extension TKRegionManager {
   public static func sortedModes(in regions: [TKRegion]) -> [TKRegion.RoutingMode] {
    let all = regions.map(\.routingModes)
    return sortedFlattenedModes(all)
  }
  
  static func sortedFlattenedModes(_ modes: [[TKRegion.RoutingMode]]) -> [TKRegion.RoutingMode] {
    guard let first = modes.first else { return [] }
    
    var added = Set<String>()
    added = added.union(first.map(\.identifier))
    var all = first
    
    for group in modes.dropFirst() {
      for (index, mode) in group.enumerated() where !added.contains(mode.identifier) {
        added.insert(mode.identifier)
        
        if index > 0, let previousIndex = all.firstIndex(of: group[index - 1]) {
          all.insert(mode, at: previousIndex + 1)
        } else if index == 0 {
          all.insert(mode, at: 0)
        } else {
          assertionFailure("We're merging in sequence here; how come the previous element isn't in the list? Previous is: \(group[index - 1]) from \(group)")
          all.append(mode)
        }
      }
    }
    
    // Remove specific modes for which we have the generic one
    for mode in all {
      let generic = TKTransportMode.genericModeIdentifier(forModeIdentifier: mode.identifier)
      if generic != mode.identifier, added.contains(generic) {
        added.remove(mode.identifier)
        all.removeAll { $0.identifier == mode.identifier }
      }
    }
    
    return all
  } 
}