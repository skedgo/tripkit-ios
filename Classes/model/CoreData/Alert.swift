//
//  Alert.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 2/09/2016.
//
//

import Foundation

extension Alert {
  
  public var infoIconType: STKInfoIconType {
    switch alertSeverity {
    case .info, .warning: return .warning
    case .alert: return .alert
    } 
  }
  
  /// This is an array of `stopCode`. A non-empty value indicates the alert requires a 
  /// reroute action because, e.g., the stops have become inaccessible. This property
  /// is typically passed to a routing request as stops to avoid during routing.
  public var excludedStops: [String] {
    return action?["excludedStopCodes"] as? [String] ?? []
  }
  
}


// MARK: - TKAlert

extension Alert: TKAlert {
  
  public var infoURL: URL? {
    if let url = url {
      return URL(string: url)
    } else {
      return nil
    }
  }
  
  public var icon: SGKImage? {
    return STKInfoIcon.image(for: infoIconType, usage: .normal)
  }
  
  public var iconURL: URL? {
    return imageURL
  }
  
  public var lastUpdated: Date? {
    return nil
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
