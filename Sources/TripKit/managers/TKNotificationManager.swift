//
//  TKNotificationManager.swift
//  TripKit
//
//  Created by Jules Ian Gilos on 1/16/23.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

typealias Publisher = ([UNNotificationRequest]) -> Void

public class TKNotificationManager: NSObject {
  
  // List down Notification contexts here
  let subscriptions: [NotificationSubscription] = [.init(context: .tripAlerts)]
  
  @objc(sharedInstance)
  public static let shared = TKNotificationManager()
  
  public var requests: [UNNotificationRequest] = []
  
  public func isSubscribed(to context: NotificationSubscription.Context) -> Bool {
    guard let subscription = getNotificationSubscription(from: context)
    else {
      return false
    }
    
    return subscription.isSubscribed()
  }
  
  public func add(request: UNNotificationRequest, for context: NotificationSubscription.Context) {
    guard let subscription = getNotificationSubscription(from: context)
    else {
      TKLog.warn("Adding a request to a context that is not yet available yet or unrecognized")
      return
    }
    
    subscription.add(request: request)
  }
  
  public func clearRequests() {
    subscriptions.forEach { subscription in
      subscription.clearRequests()
    }
  }
  
  public func subscribe(to context: NotificationSubscription.Context, updates: @escaping ([UNNotificationRequest]) -> Void) {
    guard let subscription = getNotificationSubscription(from: context)
    else {
      TKLog.warn("Subscribed to a context that is not yet available yet or unrecognized")
      return
    }
    
    subscription.subscribe(updates)
  }
  
  func getNotificationSubscription(from context: NotificationSubscription.Context) -> NotificationSubscription? {
    guard let subscription = subscriptions.first(where: { $0.context == context })
    else {
      return nil
    }
    
    return subscription
  }
  
}

public class NotificationSubscription {
  public enum Context {
    case tripAlerts
    case none
    
    var identifier: String {
      let base = "tripkit.notification."
      var append: String
      switch self {
      case .tripAlerts: append = "trip_alerts"
      case .none: append = "unknown"
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
  
  public func isSubscribed() -> Bool {
    return publisher != nil
  }
  
  public func add(request: UNNotificationRequest) {
    self.requests.append(request)
    publisher?(requests)
  }
  
  public func subscribe(_ updates: @escaping ([UNNotificationRequest]) -> Void) {
    if isSubscribed() {
      TKLog.warn("TKNotificationManager is already subscribed, the old subscriber will not get updates anymore.")
    }
    
    publisher = updates
  }
  
  public func clearRequests() {
    requests.removeAll()
  }
  
}
