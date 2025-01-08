//
//  TKAPI+TripKit.swift
//  TripKit
//
//  Created by Adrian Schönig on 19/11/2024.
//


extension TKAPI.RegionInfo {
  
  /// - Parameter modeIdentifier: A mode identifier
  /// - Returns: The specific mode details for this this mode identifier
  ///     (only returns something if it's a specific mode identifier, i.e.,
  ///     one with two underscores in it.)
  public func specificModeDetails(for modeIdentifier: String) -> TKAPI.SpecificModeDetails? {
    let genericMode = TKTransportMode.genericModeIdentifier(forModeIdentifier: modeIdentifier)
    return modes[genericMode]?.specificModes.first { modeIdentifier == $0.identifier }
  }
  
}

extension TKAPI.SegmentVisibility {
  var tkVisibility: TKTripSegmentVisibility {
    switch self {
    case .inSummary: return .inSummary
    case .onMap: return .onMap
    case .inDetails: return .inDetails
    case .hidden: return .hidden
    }
  }
}

extension TKAPI.SegmentType {
  var tkType: TKSegmentType {
    switch self {
    case .stationary: return .stationary
    case .scheduled: return .scheduled
    case .unscheduled: return .unscheduled
    }
  }
}
