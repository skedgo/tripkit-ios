//
//  TKUITripMonitorManager.swift
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

/// The manager for trip notifications such as "get off at the next stop" or "your trip is about to start"
///
/// Requirements:
/// - Project > Your Target > Capabilities > Background Modes: Enable "Location Updates"
/// - Project > Your Target > Info: Include both `NSLocationAlwaysAndWhenInUseUsageDescription` and `NSLocationWhenInUseUsageDescription`
/// - Then call `TKUINotificationManager.shared.subscribe(to: .tripAlerts) { ... }` in your app.
@available(iOS 14.0, *)
public class TKUITripMonitorManager: NSObject {
  
  private enum Keys {
    static let alertsEnabled = "GODefaultGetOffAlertsEnabled"
  }
  
  @objc(sharedInstance)
  public static let shared = TKUITripMonitorManager()
  
  private lazy var geoMonitor: GeoMonitor = {
    return .init(enabledKey: Keys.alertsEnabled) { [weak self] _ in
      guard let self else { return [] }
      return self.geofences.map(\.1)
    } onEvent: { [weak self] event in
      guard let self else { return }
      switch event {
      case .entered(let region, _):
        guard let match = self.geofences.first(where: { $0.1.identifier == region.identifier })?.0 else { return }
        self.notify(with: match, trigger: nil)  // Fire right away
      case .manual(let region, let location):
        break // This happens we starting in a region. Ignore.
      case .status(let message, let status):
        TKLog.info("TKUITripMonitorManager", text: message)
      }
    }
  }()
  
  var geofences: [(TKAPI.TripNotification, CLCircularRegion)] = []
  
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
    guard let identifier = trip.saveURL?.lastPathComponent ?? trip.tripId
    else {
      return nil
    }
    return identifier
  }
  
  public func monitorRegions(from trip: Trip) {
    // Since only one trip can have notifications at a time, there is no need to save other trips, just need to replace the current one.
    
    let notifications = trip.segments.flatMap(\.notifications)
    guard !notifications.isEmpty else {
      return stopMonitoring()
    }
    
    startMonitoringRegions(from: notifications)
    scheduleTimeBased(from: notifications)
  }
  
  
  public func stopMonitoring() {
    stopMonitoringRegions()
  }
  
  private func notify(with tripNotification: TKAPI.TripNotification, trigger: UNNotificationTrigger?) {
    let notification = UNMutableNotificationContent()
    notification.title = tripNotification.messageTitle
    notification.body = tripNotification.messageBody
    notification.sound = .default
    
    let request = UNNotificationRequest(
      identifier: tripNotification.id,
      content: notification,
      trigger: trigger
    )
    
    TKUINotificationManager.shared.add(request: request, for: .tripAlerts)
  }
  
}

// MARK: - Geofence-based alerts

@available(iOS 14.0, *)
extension TKUITripMonitorManager {
  
  private func startMonitoringRegions(from notifications: [TKAPI.TripNotification]) {
    let pairs: [(TKAPI.TripNotification, CLCircularRegion)] = notifications.compactMap { notification -> (TKAPI.TripNotification, CLCircularRegion)? in
      switch notification.kind {
      case let .circle(center, radius, _):
        let region = CLCircularRegion(center: center, radius: radius, identifier: notification.id)
        return (notification, region)
      case .time:
        return nil
      }
    }
    self.geofences = pairs
    
    guard !pairs.isEmpty else { return }
    
    geoMonitor.startMonitoring()
    
    // Keep GPS active and enable blue indicator, which allows the app to
    // keep monitoring in the background, even when only using "When in use"
    // permissions. This will then also allow alerts to fire from the
    // background. Also, user can tap status bar indicator to re-open app.
    geoMonitor.isTracking = true
    
    Task {
      await geoMonitor.update(regions: pairs.map(\.1))
    }
  }
  
  private func stopMonitoringRegions() {
    guard !geofences.isEmpty else { return }
    
    geoMonitor.isTracking = false
    geoMonitor.stopMonitoring()
    
    // inverse of `monitorRegion(from:)`
    self.geofences = []
  }
  
}

// MARK: - Time-based alerts

@available(iOS 14.0, *)
extension TKUITripMonitorManager {
  
  private func scheduleTimeBased(from notifications: [TKAPI.TripNotification]) {
    for notification in notifications {
      guard case let .time(fireDate) = notification.kind else { continue }
      let fireIn = fireDate.timeIntervalSinceNow
      
      // Don't bother scheduling an alert for leaving sooner than a minute from now
      guard fireIn > 60 else { continue }
      
      notify(with: notification, trigger: UNTimeIntervalNotificationTrigger(timeInterval: fireIn, repeats: false))
    }
  }
  
}
