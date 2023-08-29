//
//  Shape+Data.swift
//  TripKit
//
//  Created by Adrian Schönig on 24/5/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS)
import UIKit
#endif

extension Shape: DataAttachable {}

extension Shape {
  public enum RoadSafety: Comparable {
    /// Just for this mode
    case safe
    
    /// Designated for this mode, but not exclusively
    case designated
    
    /// Shared, but could be worse, e.g., it's quiet or others are aware of you
    case neutral
    
    /// Shared, and busy
    case hostile
    
    #if os(iOS) || os(tvOS)
    public var color: UIColor {
      switch self {
      case .safe: return .tkStateSuccess
      case .designated: return .blue
      case .neutral: return #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
      case .hostile: return .tkStateWarning
      }
    }
    #endif
  }
  
  public enum RoadTag: String, Codable {
    case cycleLane = "CYCLE-LANE"
    case cycleTrack = "CYCLE-TRACK"
    case cycleNetwork = "CYCLE-NETWORK"
    //case bicycleDesignated = "BICYCLE-DESIGNATED" -- not sure what this is
    case bicycleBoulevard = "BICYCLE-BOULEVARD"
    case sideWalk = "SIDE-WALK"
    case mainRoad = "MAIN-ROAD"
    case sideRoad = "SIDE-ROAD"
    case sharedRoad = "SHARED-ROAD"
    //case unpavedOrUnsealed = "UNPAVED/UNSEALED" -- fine to ignore
    case streetLight = "STREET-LIGHT"
    case CCTVCamera = "CCTV-CAMERA"
    
    public var localized: String {
      switch self {
      case .cycleLane: return "Cycle Lane"
      case .cycleTrack: return "Cycle Track"
      case .cycleNetwork: return "Cycle Network"
      case .bicycleBoulevard: return "Bicycle Boulevard"
      case .sideWalk: return "Side Walk"
      case .sideRoad: return "Side Road"
      case .sharedRoad: return "Shared Road"
      case .mainRoad: return "Main Road"
      case .streetLight: return "Street Light"
      case .CCTVCamera: return "CCTV Camera"
      }
    }
    
    public var safety: RoadSafety {
      switch self {
      case .cycleTrack:
        return .safe
      case .cycleLane,
           .cycleNetwork,
           .bicycleBoulevard,
           .CCTVCamera:
        return .designated
      case .sideWalk,
           .sideRoad,
           .sharedRoad,
           .streetLight:
        return .neutral
      case .mainRoad:
        return .hostile
      }
    }
  }
  
  /// Name of the "cycling network" that this segment is part of
  @objc
  public var cyclingNetwork: String? {
    get { decodePrimitive(String.self, key: "cyclingNetwork") }
    set { encodePrimitive(newValue, key: "cyclingNetwork") }
  }

  public var roadTags: [RoadTag]? {
    get { decode([RoadTag].self, key: "roadTags") }
    set { encode(newValue, key: "roadTags") }
  }

}
