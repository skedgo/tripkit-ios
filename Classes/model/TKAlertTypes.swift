//
//  TKAlertTypes.swift
//  TripKit
//
//  Created by Adrian Schoenig on 28/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import Marshal

public struct TKAlertWrapper: Unmarshaling {
  public let alert: TKAlert
  public let operators: [String]?
  public let serviceTripIDs: [String]?
  public let stopCodes: [String]?
  public let routeIDs: [String]?

  public init(object: MarshaledObject) throws {
    let simpleAlert: TKSimpleAlert = try object.value(for: "alert")
    alert = simpleAlert
    routeIDs = try? object.value(for: "routeIDs")
    stopCodes = try? object.value(for: "stopCodes")
    serviceTripIDs = try? object.value(for: "serviceTripIDs")
    operators = try? object.value(for: "operators")
  }
}

class TKSimpleAlert: NSObject, Unmarshaling, TKAlert {
  public let title: String?
  public let text: String?
  public let infoURL: URL?
  public let iconURL: URL?
  @objc public let severity: AlertSeverity
  public let lastUpdated: Date?
  
  public var icon: SGKImage? {
    let iconType: STKInfoIconType
    switch severity {
    case .info, .warning:
      iconType = .warning
    case .alert:
      iconType = .alert
    }
    
    return STKInfoIcon.image(for: iconType, usage: .normal)
  }
  
  public required init(object: MarshaledObject) throws {
    title = try object.value(for: "title")
    text = try? object.value(for: "text")
    infoURL = try? object.value(for: "url")
    iconURL = try? object.value(for: "iconURL")
    lastUpdated = try? object.value(for: "lastUpdate")
    
    // for some reason this doesn't work
    // severity = object.value(for: "severity")
    severity = AlertSeverity(rawValue: (try? object.value(for: "severity")) ?? 0) ?? .info
  }
}

// MARK: - Protocol

@objc public protocol TKAlert {
  
  var icon: SGKImage? { get }
  var iconURL: URL? { get }
  var title: String? { get } // really not optional, but for compatibility with MKAnnotation
  var text: String? { get }
  var infoURL: URL? { get }
  var lastUpdated: Date? { get }
  
}

// MARK: - Helper Extensions -

extension AlertSeverity: ValueType {
  public static func value(from object: Any) throws -> AlertSeverity {
    guard let rawValue = object as? String else {
      throw MarshalError.typeMismatch(expected: String.self, actual: type(of: object))
    }
    switch rawValue {
    case "alert": return .alert
    case "warning": return .warning
    default: return .info
    }
  }
  
}
