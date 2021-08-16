//
//  Alert+CoreDataClass.swift
//  TripKit
//
//  Created by Adrian Schönig on 12/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Alert)
public class Alert: NSManagedObject {

}

public enum TKAlertSeverity: Int {
  case info     = -1
  case warning  = 0
  case alert    = 1
}

extension Alert {
  
  // Constants
  public enum ActionTypeIdentifier {
    static let excludingStopsFromRouting: String = "excludedStopCodes"
  }
  
  public static func fetch(hashCode: NSNumber, in context: NSManagedObjectContext) -> Alert? {
    return context.fetchUniqueObject(Alert.self, predicate: NSPredicate(format: "hashCode = %@", hashCode))
  }
  
  public var alertSeverity: TKAlertSeverity {
    get {
      TKAlertSeverity(rawValue: Int(severity)) ?? .warning
    }
    set {
      severity = Int16(newValue.rawValue)
    }
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
