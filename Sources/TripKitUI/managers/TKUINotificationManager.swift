//
//  TKUINotificationManager.swift
//  TripKit
//
//  Created by Jules Ian Gilos on 1/16/23.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import UserNotifications

import TripKit

typealias Publisher = ([UNNotificationRequest]) -> Void

public class TKUINotificationManager: NSObject {
  
  public weak var delegate: TKUINotificationManagerDelegate?
  
  // List down Notification contexts here
  let subscriptions: [TKUINotificationSubscription] = [.init(context: .tripAlerts), .init(context: .pushNotifications)]
  
  @objc(sharedInstance)
  public static let shared = TKUINotificationManager()
  
  /// Clears all the requests for all notification subscriptions
  public func subscribe(to context: TKUINotificationSubscription.Context, updates: @escaping ([UNNotificationRequest]) -> Void) {
    guard let subscription = getNotificationSubscription(from: context)
    else {
      TKLog.warn("Subscribed to a context that is not yet available yet or unrecognized")
      return
    }
    
    subscription.subscribe(updates)
  }
  
  /// Gets the list of requests that are pending for the provided notification context
  public func getRequests(from context: TKUINotificationSubscription.Context) -> [UNNotificationRequest] {
    guard let subscription = getNotificationSubscription(from: context)
    else {
      return []
    }
    
    return subscription.getRequests()
  }
  
  /// Determines if the provided notification context is subscribed or not
  public func isSubscribed(to context: TKUINotificationSubscription.Context) -> Bool {
    guard let subscription = getNotificationSubscription(from: context)
    else {
      return false
    }
    
    return subscription.isSubscribed()
  }
  
  /// Clears the requests for the provided notification context
  public func clearRequests(of context: TKUINotificationSubscription.Context) {
    guard let subscription = getNotificationSubscription(from: context)
    else {
      return
    }
    
    subscription.clearRequests()
  }
  
  /// Clears all the requests for all notification subscriptions
  public func clearAllRequests() {
    subscriptions.forEach { subscription in
      subscription.clearRequests()
    }
  }
  
  /// Adds a notification request for the provided context
  func add(request: UNNotificationRequest, for context: TKUINotificationSubscription.Context) {
    guard let subscription = getNotificationSubscription(from: context)
    else {
      TKLog.warn("Adding a request to a context that is not yet available yet or unrecognized")
      return
    }
    
    subscription.add(request: request)
  }
  
  func getNotificationSubscription(from context: TKUINotificationSubscription.Context) -> TKUINotificationSubscription? {
    guard let subscription = subscriptions.first(where: { $0.context == context })
    else {
      return nil
    }
    
    return subscription
  }
  
}

public protocol TKUINotificationManagerDelegate: AnyObject {
  
  /// Check and, if necessary, ask for notification permissions. If no permissions are granted, this
  /// should then also directly show an appropriate alert about how to enable them.
  ///
  /// - Returns: Whether notifications are enabled for this device or permissions are not determined
  func notificationsPermissionsNeeded() async -> Bool
  
  /// Called before subscribing to push notifications for a specifc trip.
  ///
  /// This should then make sure that `TKServer.shared.userToken` is set before returning.
  /// If this can't be set, it should throw an error.
  ///
  /// Only needed to implement, when enabling push notification-based trip notifications
  func notificationRequireUserToken() async throws
}

extension TKUINotificationManagerDelegate {
  public func notificationRequireUserToken() async throws {}
}

public class TKUINotificationSubscription {
  public enum Context {
    case tripAlerts
    case pushNotifications
    
    public var identifier: String {
      let base = "tripkit.notification."
      var append: String
      switch self {
      case .tripAlerts: append = "trip_alerts"
      case .pushNotifications: append = "push_notifications"
      }
      return "\(base)\(append)"
    }
  }
  
  var context: Context
  var requests: [UNNotificationRequest] = []
  var publisher: Publisher?
  
  init(context: Context) {
    self.context = context
  }
  
  public func getRequests() -> [UNNotificationRequest] {
    return requests
  }
  
  public func isSubscribed() -> Bool {
    return publisher != nil
  }
  
  public func add(request: UNNotificationRequest) {
    self.requests.append(request)
    publisher?(requests)
  }
  
  public func subscribe(_ updates: @escaping ([UNNotificationRequest]) -> Void) {
    if isSubscribed() {
      TKLog.warn("TKUINotificationManager is already subscribed, the old subscriber will not get updates anymore.")
    }
    
    publisher = updates
  }
  
  public func clearRequests() {
    requests.removeAll()
  }
  
}
