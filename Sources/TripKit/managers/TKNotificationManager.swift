//
//  TKNotificationManager.swift
//  TripKit
//
//  Created by Jules Ian Gilos on 1/16/23.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

// Note: RxSwift public variables causes compilation errors, probably an import issue. Did not resolve this since this means making RxSwift public to the importing project. Used @Published instead
// Note: Just made UNNotificationRequest as output instead of making a Custom Payload object so that in first glance it is recognizable as a Notification.

public class TKNotificationManager: NSObject {
  
  public static let identifier = "tripkit.notification"
  
  @objc(sharedInstance)
  public static let shared = TKNotificationManager()
  
  @Published public var requests: [UNNotificationRequest] = []
  
  public func add(request: UNNotificationRequest) {
    requests.append(request)
  }
  
  public func clearRequests() {
    requests.removeAll()
  }
  
}
