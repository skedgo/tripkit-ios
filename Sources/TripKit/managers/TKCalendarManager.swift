//
//  TKCalendarManager.swift
//  TripKit
//
//  Created by Adrian Schoenig on 20/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation
import EventKit

public class TKCalendarManager: NSObject {
  
  @objc(sharedInstance)
  public static let shared = TKCalendarManager()
  
  @objc
  public private(set) var eventStore = EKEventStore()
  
  public var openSettingsHandler: (() -> Void)? = nil
  
  var helperGeocoder: TKGeocoding?
  
  /// `<event title> (<weekday, <month> <day> from/till <time>)`
  public static func title(for event: EKEvent) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE, dd MMM, h a"
    formatter.timeStyle = .short
    formatter.dateStyle = .medium
    formatter.doesRelativeDateFormatting = true
    formatter.locale = .current
    formatter.timeZone = event.timeZone ?? .current
    
    let title = event.title ?? "Event"
    let date = formatter.string(from: event.startDate)
    return "\(title) (\(date)))"
  }
  
  @objc(fetchEventsBetweenDate:andEndDate:fromCalendars:)
  public func fetchEvents(start: Date, end: Date, from calendars: [EKCalendar]? = nil) -> [EKEvent] {
    guard isAuthorized else { return [] }
    let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: calendars)
    return eventStore.events(matching: predicate)
  }
  
  
  /// Fetches and returns all the users events between (roughly) yesterday and 1 week from now.
  public func fetchUpcomingEvents(from calendars: [EKCalendar]? = nil) -> [EKEvent] {
    guard isAuthorized else { return [] }
    let previousMidnight = Date().midnight(in: .current)
    let start = previousMidnight.addingTimeInterval(-24 * 60 * 60)
    let end = previousMidnight.addingTimeInterval(7 * 24 * 60 * 60)
    return fetchEvents(start: start, end: end, from: calendars)
  }
  
  public func fetchEvents(matching string: String) -> [EKEvent] {
    let needle = string.lowercased()
    let matches = fetchUpcomingEvents()
      .lazy
      .filter { event in
        event.location?.lowercased().contains(needle) == true
        || event.title?.lowercased().contains(needle) == true
      }
      .prefix(10)
    return Array(matches)
  }
}

//MARK: - TKPermissionManager overrides

extension TKCalendarManager: TKPermissionManager {
  
  public var authorizationStatus: TKAuthorizationStatus {
    switch EKEventStore.authorizationStatus(for: .event) {
    case .notDetermined:
      return .notDetermined
    case .restricted:
      return .restricted
#if swift(>=5.9) // Proxy for Xcode 15+
    case .writeOnly:
      return .denied
    case .fullAccess:
      return .authorized
#endif
    case .denied:
      return .denied
    case .authorized:
      return .authorized
    @unknown default:
      return .notDetermined
    }
  }
  
  public func askForPermission(_ completion: @escaping (Bool) -> Void) {
    let oldStore = self.eventStore
#if swift(>=5.9) // Proxy for Xcode 15+
    if #available(iOS 17.0, macOS 14.0, *) {
      oldStore.requestFullAccessToEvents { granted, _ in
        self.eventStore = .init()
        DispatchQueue.main.async {
          completion(granted)
        }
      }
    } else {
      oldStore.requestAccess(to: .event) { granted, _ in
        self.eventStore = .init()
        DispatchQueue.main.async {
          completion(granted)
        }
      }
    }
#else
    oldStore.requestAccess(to: .event) { granted, _ in
      self.eventStore = .init()
      DispatchQueue.main.async {
        completion(granted)
      }
    }
#endif
  }
  
  public var authorizationAlertText: String {
    NSLocalizedString("You previously denied this app access to your calendar. Please go to the Settings app > Privacy > Calendar and authorise this app to use this feature.", tableName: "Shared", bundle: .tripKit, comment: "Calendar authorisation needed text")
  }
  
}
