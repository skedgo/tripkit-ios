//
//  Shape+Data.swift
//  TripKit
//
//  Created by Adrian Schönig on 24/5/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

#if canImport(CoreData)

import Foundation

#if canImport(UIKit)
import UIKit
#endif

extension Shape: DataAttachable {}

extension Shape {
    
  /// Name of the "cycling network" that this segment is part of
  @objc
  public var cyclingNetwork: String? {
    get { decodePrimitive(String.self, key: "cyclingNetwork") }
    set { encodePrimitive(newValue, key: "cyclingNetwork") }
  }

  public var roadTags: [TKAPI.RoadTag]? {
    get { decode([TKAPI.RoadTag].self, key: "roadTags") }
    set { encode(newValue, key: "roadTags") }
  }
  
  func distanceByRoadTag() -> [TKAPI.RoadTag: Double]? {
    guard routeIsTravelled, let distance = metres?.doubleValue else { return nil }
    
    var distancesByTag = [TKAPI.RoadTag: Double]()
    if let tags = roadTags, !tags.isEmpty {
      for tag in tags {
        distancesByTag[tag, default: 0] += distance
      }
    } else {
      distancesByTag[.other, default: 0] += distance
    }
    return distancesByTag
  }

}

extension TKAPI.RoadTag {
  public var localized: String {
    switch self {
    case .cycleLane: return "Cycle Lane"
    case .cycleTrack: return "Cycle Track"
    case .cycleNetwork: return "Cycle Network"
    case .bicycleDesignated: return "Designated for Cyclists"
    case .bicycleBoulevard: return "Bicycle Boulevard"
    case .sideWalk: return "Side Walk"
    case .sideRoad: return "Side Road"
    case .sharedRoad: return "Shared Road"
    case .mainRoad: return "Main Road"
    case .streetLight: return "Street Light"
    case .CCTVCamera: return "CCTV Camera"
    case .litRoute: return "Lit Route"
    case .other: return "Other"
    }
  }
}

extension TKAPI.RoadSafety {
#if canImport(UIKit)
    public var color: UIColor {
      switch self {
      case .safe: return .tkStateSuccess
      case .designated: return .blue
      case .neutral: return #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
      case .hostile: return .tkStateWarning
      case .unknown: return .systemGray
      }
    }
#endif
}

#endif
