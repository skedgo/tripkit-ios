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
import Combine

import GeoMonitor
import TripKit

/// The manager for trip notifications such as "get off at the next stop" or "your trip is about to start"
///
/// ### Requirements:
/// - Project > Your Target > Capabilities > Background Modes: Enable "Location Updates"
/// - Project > Your Target > Info: Include both `NSLocationAlwaysAndWhenInUseUsageDescription` and `NSLocationWhenInUseUsageDescription`
/// - Then call `TKUINotificationManager.shared.subscribe(to: .tripAlerts) { ... }` in your app.
///
/// ### Push notifications:
///
/// An additional feature is server-side notifications related to a trip being monitored. This requires additional
/// set-up:
///
/// - Implement `TKUINotificationPushProvider` and set it on `TKUINotificationManager.shared.pushProvider`
/// - Lastly, call `TKUINotificationManager.shared.subscribe(to: .pushNotifications) { _ in }`
///
@MainActor
@available(iOS 14.0, *)
public class TKUITripMonitorManager: NSObject, ObservableObject {
  
  /// Will be set on `UNNotificationRequest.content.categoryIdentifier`
  ///
  /// These notifications will also get `UNNotificationRequest.identifier` set to `TKAPI.TripNotification.id`
  nonisolated
  public static let tripNotificationCategoryIdentifier: String = "TKUITripMonitorManager.trip-notification"
  
  private enum Keys {
    static let alertsEnabled = "GODefaultGetOffAlertsEnabled"
    static let monitoredTrip = "GOMonitoredTrip"
  }
  
  struct MonitoredTrip: Codable, Hashable {
    let tripID: String?
    let tripURL: URL
    let unsubscribeURL: URL?
    let notifications: [TKAPI.TripNotification]
    let departureTime: Date?
  }
  
  @objc(sharedInstance)
  public static let shared = TKUITripMonitorManager()
  
  private lazy var geoMonitor: GeoMonitor = {
    return .init(enabledKey: Keys.alertsEnabled) { [weak self] _ in
      guard let monitoredTrip = self?.monitoredTrip else { return [] }
      
      if let departureTime = monitoredTrip.departureTime, departureTime.timeIntervalSinceNow > 6 * 3600 {
        // Ignore location-based notifications for trips departing more than 6
        // hours from now. This closure should get called again within those
        // 6 hours and the regions get added then.
        return []
      }
      
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
  
  @Published var isTogglingAlert: Bool = false
  
  var isTogglingAlertPublisher: AnyPublisher<Bool, Never> {
    _isTogglingAlert.projectedValue.eraseToAnyPublisher()
  }
  
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
  public func monitorRegions(from trip: Trip, includeTimeToLeaveNotification: Bool = true) async throws {
    // Since only one trip can have notifications at a time, there is no need to save other trips, just need to replace the current one.

    if monitoredTrip != nil {
      await stopMonitoring()
    }

    let notifications = trip
      .notifications(includeTimeToLeaveNotification: includeTimeToLeaveNotification)
      .sorted { $0.messageKind.rawValue < $1.messageKind.rawValue }
    guard !notifications.isEmpty else {
      return
    }

    // Subscribe to push-notifications, if enabled
    if let provider = TKUINotificationManager.shared.pushProvider, provider.notificationPushEnabled(), let subscribeURL = trip.subscribeURL {
      // If this fails, it'll abort enabling notifications
      try await provider.notificationRequireUserToken()
      let _ = await TKServer.shared.hit(url: subscribeURL)
    }

    // ... and then start the location the trip notifications
    
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
      unsubscribeURL: trip.unsubscribeURL,
      notifications: notifications,
      departureTime: trip.departureTime
    ))
    
    if includeTimeToLeaveNotification {
      scheduleTimeBased(from: notifications)
    }
  }
  
  public func stopMonitoring() async {
    if let provider = TKUINotificationManager.shared.pushProvider, let monitoredTrip, let unsubscribeURL = monitoredTrip.unsubscribeURL {
      // If this fails, we'll disable the local notifications anyway
      try? await provider.notificationRequireUserToken()
      let _ = await TKServer.shared.hit(url: unsubscribeURL)
    }

    stopMonitoringRegions()
  }
  
  private func notify(with tripNotification: TKAPI.TripNotification, trigger: UNNotificationTrigger?) {
    assert(tripNotification.kind != .pushNotification, "Push notifications should only be triggered by backend; not locally!")
    
    let notification = UNMutableNotificationContent()
    notification.categoryIdentifier = Self.tripNotificationCategoryIdentifier
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
  
  public struct GeofenceMatch {
    public let trip: Trip
    public let segment: TKSegment
    public let notification: TKAPI.TripNotification
  }
  
  public func match(geofenceID: String) -> GeofenceMatch? {
    guard
      let monitoredTrip,
      let trip = Trip.find(tripURL: monitoredTrip.tripURL, in: TripKit.shared.tripKitContext)
    else { return nil }
    
    for segment in trip.segments {
      if let notification = segment.notifications.first(where: { $0.id == geofenceID }) {
        return .init(trip: trip, segment: segment, notification: notification)
      }
    }

    TKLog.warn("TKUITripMonitorManager", text: "Could not find matching notification for \(geofenceID).")
    return nil
  }
  
}

// MARK: - Geofence-based alerts

extension TKAPI.TripNotification {
  var region: CLCircularRegion? {
    switch kind {
    case let .circle(center, radius, _):
      return CLCircularRegion(center: center, radius: radius, identifier: id)
    case .time, .pushNotification:
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
