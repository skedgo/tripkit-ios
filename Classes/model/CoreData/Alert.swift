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
  
  @objc public var infoIconType: STKInfoIconType {
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

// MARK: - STKDisplayablePoint

extension Alert: STKDisplayablePoint {

  public var pointClusterIdentifier: String? {
    return nil
  }
  
  public var pointDisplaysImage: Bool {
    return location != nil
  }
  
  public var pointImage: SGKImage? {
    return STKInfoIcon.image(for: infoIconType, usage: .map)
  }
  
  public var pointImageURL: URL? {
    return imageURL
  }
  
  public var isDraggable: Bool {
    return false
  }
  
}
