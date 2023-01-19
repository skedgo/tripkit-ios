//
//  TKUIGeoMonitorManager.swift
//  TripKitUI-iOS
//
//  Created by Jules Ian Gilos on 1/12/23.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UserNotifications
import CoreLocation

import GeoMonitor
import TripKit

/// The manager for geofence-based alerts for a trip, e.g., "get off at the next stop"
///
/// Requirements:
/// - Project > Your Target > Capabilities > Background Modes: Enable "Location Updates"
/// - Project > Your Target > Info: Include both `NSLocationAlwaysAndWhenInUseUsageDescription` and `NSLocationWhenInUseUsageDescription`
/// - Then call `TKUINotificationManager.shared.subscribe(to: .tripAlerts) { ... }` in your app.
public class TKUIGeoMonitorManager: NSObject {
  
  private enum Keys {
    static let alertsEnabled = "GODefaultGetOffAlertsEnabled"
  }
  
  @objc(sharedInstance)
  public static let shared = TKUIGeoMonitorManager()
  
  private lazy var geoMonitor: GeoMonitor = {
    return .init(enabledKey: Keys.alertsEnabled) { [weak self] _ in
      guard let self else { return [] }
      return self.geofences.map(\.1)
    } onEvent: { [weak self] event in
      guard let self else { return }
      switch event {
      case .entered(let region, _):
        guard let match = self.geofences.first(where: { $0.1.identifier == region.identifier })?.0 else { return }
        self.notify(with: match)
      case .manual(let region, let location):
        break
      case .status(let message, let status):
        break
      }
    }
  }()
  
  var geofences: [(TKAPI.Geofence, CLCircularRegion)] = []
  
  override init() {
    super.init()
  }
  
  public func getPreference(for trip: Trip) -> Bool {
    let identifiers = enabledIdentifiers()
    
    guard let identifier = identifier(from: trip)
    else {
      return false
    }
    
    return identifiers.contains(identifier)
  }
  
  public func setAlertsEnabled(_ enabled: Bool, for trip: Trip) {
    if enabled,
       !TKUINotificationManager.shared.isSubscribed(to: .tripAlerts) {
      TKLog.warn("TKUINotificationManager is not subscribed yet, location updates will not be notified")
    }
    setPreference(alertsEnabled: enabled, for: trip)
    
    guard enabled
    else {
      stopMonitoring()
      return
    }
    
    monitorRegions(from: trip)
  }
  
  private func setPreference(alertsEnabled: Bool, for trip: Trip) {
    guard let identifier = identifier(from: trip)
    else {
      assertionFailure("Failed to set Identifier, check saveURL's existence")
      return
    }
    
    let identifiers = alertsEnabled ? [identifier] : []
    
    /* LATER: If needs multiple trips at once; make the above a `var` and then:
    if alertsEnabled {
      identifiers.append(identifier)
    } else {
      identifiers.removeAll { $0 == identifier }
    }
    */
    
    UserDefaults.shared.set(identifiers, forKey: Keys.alertsEnabled)
  }
  
  /// This contains the list of trip ids that the user had set Alerts on.
  private func enabledIdentifiers() -> [String] {
    return UserDefaults.shared.stringArray(forKey: Keys.alertsEnabled) ?? []
  }
  
  private func identifier(from trip: Trip) -> String? {
    guard let identifier = trip.saveURL?.lastPathComponent
    else {
      return nil
    }
    return identifier
  }
  
  public func monitorRegions(from trip: Trip) {
    // Since only one trip can have notifications at a time, there is no need to save other trips, just need to replace the current one.
    
    let geofences = trip.segments.flatMap(\.geofences)
    guard !geofences.isEmpty else {
      return stopMonitoring()
    }
    
    let pairs = geofences.map { geofence -> (TKAPI.Geofence, CLCircularRegion) in
      switch geofence.kind {
      case let .circle(center, radius):
        let region = CLCircularRegion(center: center, radius: radius, identifier: geofence.id)
        return (geofence, region)
      }
    }
    self.geofences = pairs
    
    startMonitoring()
    
    Task {
      await geoMonitor.update(regions: pairs.map(\.1))
    }
  }
  
  private func startMonitoring() {
    geoMonitor.enableInBackground = true
    geoMonitor.startMonitoring()
  }
  
  public func stopMonitoring() {
    geoMonitor.enableInBackground = false
    geoMonitor.stopMonitoring()
    
    // inverse of `monitorRegion(from:)`
    self.geofences = []
  }

  private func notify(with geofence: TKAPI.Geofence) {
    let notification = UNMutableNotificationContent()
    notification.title = geofence.messageTitle
    notification.body = geofence.messageBody
    notification.sound = .default
    
    let request = UNNotificationRequest(
      identifier: geofence.id,
      content: notification,
      trigger: nil // Fire right away
    )
    
    TKUINotificationManager.shared.add(request: request, for: .tripAlerts)
  }
  
}
