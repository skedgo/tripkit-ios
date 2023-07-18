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
@MainActor
@available(iOS 14.0, *)
public class TKUITripMonitorManager: NSObject, ObservableObject {
  
  private enum Keys {
    static let alertsEnabled = "GODefaultGetOffAlertsEnabled"
    static let monitoredTrip = "GOMonitoredTrip"
  }
  
  struct MonitoredTrip: Codable, Hashable {
    let tripID: String?
    let tripURL: URL
    let notifications: [TKAPI.TripNotification]
  }
  
  @objc(sharedInstance)
  public static let shared = TKUITripMonitorManager()
  
  private lazy var geoMonitor: GeoMonitor = {
    return .init(enabledKey: Keys.alertsEnabled) { [weak self] _ in
      guard let monitoredTrip = self?.monitoredTrip else { return [] }
      return monitoredTrip.notifications.compactMap(\.region)
      
    } onEvent: { [weak self] event in
      guard let self, let monitoredTrip = self.monitoredTrip else { return }
      switch event {
      case .entered(let region, _):
        guard let match = monitoredTrip.notifications.first(where: { $0.id == region.identifier }) else { return }
        self.notify(with: match, trigger: nil)  // Fire right away
      case .manual(let region, let location):
        break // This happens we starting in a region. Ignore.
      case .status(let message, let status):
        TKLog.info("TKUITripMonitorManager", text: message)
      }
    }
  }()
  
  @Published var monitoredTrip: MonitoredTrip? {
    didSet {
      do {
        if let monitoredTrip {
          let data = try JSONEncoder().encode(monitoredTrip)
          UserDefaults.shared.set(data, forKey: Keys.monitoredTrip)
        } else {
          UserDefaults.shared.removeObject(forKey: Keys.monitoredTrip)
        }
      } catch {
        TKLog.error("TKUITripMonitorManager", text: "Failed to persist monitored trip: \(error)")
      }
    }
  }
  
  override init() {
    super.init()
    
    if let data = UserDefaults.shared.data(forKey: Keys.monitoredTrip) {
      // Save to ignore errors here which might haven if app is updated
      // and old data model doesn't match anymore.
      self.monitoredTrip = try? JSONDecoder().decode(MonitoredTrip.self, from: data)
    }
  }
  
  @MainActor
  public func monitorRegions(from trip: Trip, includeTimeToLeaveNotification: Bool = true) async {
    // Since only one trip can have notifications at a time, there is no need to save other trips, just need to replace the current one.
    
    let notifications = trip
      .notifications(includeTimeToLeaveNotification: includeTimeToLeaveNotification)
      .sorted { $0.messageKind.rawValue < $1.messageKind.rawValue }
    guard !notifications.isEmpty else {
      return stopMonitoring()
    }
    
    let tripURL: URL
    do {
      tripURL = try await TKShareURLProvider.getShareURL(for: trip)
    } catch {
      // Typically due to missing save URL, which is expected
      tripURL = trip.tripURL
    }
    
    startMonitoringRegions(from: .init(
      tripID: trip.tripId,
      tripURL: tripURL,
      notifications: notifications)
    )
    
    if includeTimeToLeaveNotification {
      scheduleTimeBased(from: notifications)
    }
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
  
  public func match(geofenceID: String) -> (Trip, TKSegment)? {
    guard
      let monitoredTrip,
      let trip = Trip.find(tripURL: monitoredTrip.tripURL, in: TripKit.shared.tripKitContext)
    else { return nil }
    
    if let segment = trip.segments.first(where: { $0.notifications.map(\.id).contains(geofenceID) }) {
      return (trip, segment)
    } else {
      TKLog.warn("TKUITripMonitorManager", text: "Could not find matching notification for \(geofenceID).")
      return nil
    }
  }
  
}

// MARK: - Geofence-based alerts

extension TKAPI.TripNotification {
  var region: CLCircularRegion? {
    switch kind {
    case let .circle(center, radius, _):
      return CLCircularRegion(center: center, radius: radius, identifier: id)
    case .time:
      return nil
    }
  }
}

@available(iOS 14.0, *)
extension TKUITripMonitorManager {
  
  private func startMonitoringRegions(from monitored: MonitoredTrip) {
    self.monitoredTrip = monitored
    
    let regions = monitored.notifications.compactMap(\.region)
    guard !regions.isEmpty else { return }
    
    guard geoMonitor.hasAccess else {
      geoMonitor.ask() { [unowned self] success in
        if success {
          self.startMonitoringRegions(from: monitored)
        }
      }
      return
    }
    
    geoMonitor.startMonitoring()
    
    // Keep GPS active and enable blue indicator, which allows the app to
    // keep monitoring in the background, even when only using "When in use"
    // permissions. This will then also allow alerts to fire from the
    // background. Also, user can tap status bar indicator to re-open app.
    geoMonitor.isTracking = true
    
    Task {
      await geoMonitor.update(regions: regions)
    }
  }
  
  private func stopMonitoringRegions() {
    guard monitoredTrip != nil else { return }
    
    geoMonitor.isTracking = false
    geoMonitor.stopMonitoring()
    
    // inverse of `monitorRegion(from:)`
    self.monitoredTrip = nil
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
