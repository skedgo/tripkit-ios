//
//  TKGeoMonitorManager.swift
//  TripKitUI-iOS
//
//  Created by Jules Ian Gilos on 1/12/23.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import GeoMonitor
import CoreLocation

import UserNotifications

public class TKGeoMonitorManager: NSObject {
  
  enum RegionIdentifier: String {
    /// the starting stop of the trip
    case start
    /// is a stop that is in between start and end of the trip
    case regular
    /// the final stop of the trip
    case end
    /// 500m to final stop
    case nearEnd
  }
  
  private enum Constants {
    static let regularRadius: CLLocationDistance = 2_000
    static let endRadius: CLLocationDistance = 500
  }
  
  private enum Keys {
    static let alertsEnabled = "GODefaultGetOffAlertsEnabled"
  }
  
  @objc(sharedInstance)
  public static let shared = TKGeoMonitorManager()
  
  private var geoMonitor: GeoMonitor?
  
  var regions: [CLCircularRegion] = []
  
  override init() {
    super.init()
  }
  
  public func getPreference(for trip: Trip) -> Bool {
    guard let identifiers = enabledIdentifiers(),
          let identifier = identifier(from: trip)
    else {
      return false
    }
    
    return identifiers.contains(identifier)
  }
  
  public func setAlertsEnabled(_ enabled: Bool, for trip: Trip) {
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
  private func enabledIdentifiers() -> [String]? {
    return UserDefaults.shared.stringArray(forKey: Keys.alertsEnabled)
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
    
    var nearEndCoordinate: CLLocationCoordinate2D?
    var regions: [CLCircularRegion] = trip.segments.compactMap { segment in
      guard let coordinate = segment.start?.coordinate
      else {
        return nil
      }
      
      let region: CLCircularRegion =
        .init(center: coordinate,
                     radius: Constants.regularRadius,
                     identifier: segment.order.identifier.rawValue)
      
      if segment.order == .end {
        nearEndCoordinate = coordinate
      }
      
      return region
    }
    
    if let coordinate = nearEndCoordinate {
      // Add another circular region at the final stop for 500m radius detection
      let region: CLCircularRegion =
        .init(center: coordinate,
              radius: Constants.endRadius,
              identifier: RegionIdentifier.nearEnd.rawValue)
      regions.append(region)
    }
    
    monitor(regions: regions)
  }
  
  private func monitor(regions: [CLCircularRegion]) {
    guard let monitor = geoMonitor
    else {
      geoMonitor = .init(enabledKey: Keys.alertsEnabled) { trigger in
        switch trigger {
        case .manual:
          break
        case .initial:
          break
        case .visitMonitoring:
          break
        case .regionMonitoring:
          break
        case .departedCurrentArea:
          break
        }
        
        return regions
      } onEvent: { event in
        switch event {
        case .entered(let region, let location):
          guard let identifier = RegionIdentifier(rawValue: region.identifier)
          else {
            return
          }
          self.notify(with: identifier)
          break
        case .manual(let region, let location):
          break
        case .status(let message, let status):
          break
        }
      }
      
      startMonitoring()
      
      return
    }
    
    Task {
      await monitor.scheduleUpdate(regions: regions)
      
      startMonitoring()
    }
  }
  
  private func startMonitoring() {
    guard let monitor = geoMonitor
    else {
      return
    }
    monitor.enableInBackground = true
    monitor.startMonitoring()
  }
  
  private func stopMonitoring() {
    guard let monitor = geoMonitor
    else {
      return
    }
    monitor.enableInBackground = false
    monitor.stopMonitoring()
  }
  
  func notify(with regionIdentifier: RegionIdentifier) {
    let request = buildNotificationRequest(from: regionIdentifier)
    // TODO: Send out this notification request to TripGo (This is in TripKit)
  }
  
  func buildNotificationRequest(from regionIdentifier: RegionIdentifier) -> UNNotificationRequest {
    let content: UNNotificationContent
    switch regionIdentifier {
    case .start: content = Notifications.tripAboutToStart
    case .regular: content = Notifications.tripPassedStop
    case .end: content = Notifications.tripAtFinalStop
    case .nearEnd: content = Notifications.tripNearFinalStop
    }
    
    return .init(identifier: Notifications.identifier,
                 content: content,
                 trigger: Notifications.trigger)
  }
  
}

public extension TKGeoMonitorManager {
  
  enum Notifications {
    static let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
    static let identifier = "GetOffAlertsNotification"
    
    static let tripAboutToStart: UNMutableNotificationContent = {
      let notification = UNMutableNotificationContent()
      notification.title = Loc.TripAboutToStart()
      notification.body = Loc.LeavingOn(location: "Over There Station", time: "4:00 PM")
      notification.sound = .default
      return notification
    }()
    
    static let tripNearFinalStop: UNMutableNotificationContent = {
      let notification = UNMutableNotificationContent()
      notification.title = Loc.AlmostThere()
      notification.body = Loc.GettingNearDisembarkationPoint()
      notification.sound = .default
      return notification
    }()
    
    static let tripPassedStop: UNMutableNotificationContent = {
      let notification = UNMutableNotificationContent()
      notification.title = Loc.Leaving("The Mid Station")
      notification.body = Loc.Next("The Final Station")
      notification.sound = .default
      return notification
    }()
    
    static let tripAtFinalStop: UNMutableNotificationContent = {
      let notification = UNMutableNotificationContent()
      notification.title = Loc.ArrivingAtYourStop()
      notification.body = Loc.PrepareToDisembarkAt("The Final Station")
      notification.sound = .default
      return notification
    }()
  }
  
}

fileprivate extension TKSegmentOrdering {
  var identifier: TKGeoMonitorManager.RegionIdentifier {
    switch self {
    case .start: return .start
    case .regular: return .regular
    case .end: return .end
    }
  }
}
