//
//  TKSegment+Alerts.swift
//  TripKit
//
//  Created by Adrian Schönig on 23.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

#if canImport(CoreData)

import Foundation

extension TKSegment {
  
  /// Alerts that also have a location associated with them
  public var alertsWithLocation: [Alert] {
    alerts.filter { $0.location != nil }
  }

  /// Alerts that have content, such as a description or URL
  public var alertsWithContent: [Alert] {
    alerts.filter { $0.text != nil || $0.url != nil }
  }

  /// Alerts that also have an action associated with them
  public var alertsWithAction: [Alert] {
    alerts.filter { $0.action != nil }
  }

  /// Gets the first alert that requires reroute
  @objc public var reroutingAlert: Alert? {
    return alertsWithAction.first { !$0.stopsExcludedFromRouting.isEmpty }
  }
  
}

#endif
