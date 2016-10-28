//
//  TKAlertTypes.swift
//  TripKit
//
//  Created by Adrian Schoenig on 28/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import Marshal

public class TransitAlertInformation: NSObject, Unmarshaling, TKAlert {
  public let title: String
  public let text: String?
  public let infoURL: URL?
  public let iconURL: URL?
  public let severity: AlertSeverity
  public let lastUpdated: Date?
  
  public var sourceModel: AnyObject? {
    return self
  }
  
  public var icon: UIImage? {
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
    severity = try AlertSeverity.value(from: "severity")
    lastUpdated = try? object.value(for: "lastUpdate")
  }
}

// MARK: - Protocol

@objc public protocol TKAlert {
  
  var icon: UIImage? { get }
  var iconURL: URL? { get }
  var title: String { get }
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
