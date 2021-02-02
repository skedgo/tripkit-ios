//
//  Alert.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 2/09/2016.
//
//

import Foundation

extension Alert {
  
  // Constants
  public enum ActionTypeIdentifier {
    static let excludingStopsFromRouting: String = "excludedStopCodes"
  }
  
  public var imageURL: URL? {
    remoteIcon.flatMap { TKServer.imageURL(iconFileNamePart: $0, iconType: .alert) }
  }
  
  @objc public var infoIconType: TKInfoIconType {
    switch alertSeverity {
    case .info, .warning: return .warning
    case .alert: return .alert
    } 
  }
  
  /// This is an array of `stopCode`. A non-empty value indicates the alert requires a 
  /// reroute action because, e.g., the stops have become inaccessible. This property
  /// is typically passed to a routing request as stops to avoid during routing.
  public var stopsExcludedFromRouting: [String] {
    return action?[ActionTypeIdentifier.excludingStopsFromRouting] as? [String] ?? []
  }
  
}

// MARK: - MKAnnotation

extension Alert: MKAnnotation {
  
  public var coordinate: CLLocationCoordinate2D {
    if let location = location {
      return location.coordinate
    } else {
      return kCLLocationCoordinate2DInvalid
    }
  }
  
}
