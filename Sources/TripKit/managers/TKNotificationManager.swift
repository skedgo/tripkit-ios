//
//  TKNotificationManager.swift
//  TripKit
//
//  Created by Jules Ian Gilos on 1/16/23.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public class TKNotificationManager: NSObject {
  private typealias Publisher = ([UNNotificationRequest]) -> Void
  
  public static let identifier = "tripkit.notification"
  
  private var publisher: Publisher?
  
  @objc(sharedInstance)
  public static let shared = TKNotificationManager()
  
  public var requests: [UNNotificationRequest] = []
  
  public func add(request: UNNotificationRequest) {
    requests.append(request)
    
    publisher?(requests)
  }
  
  public func clearRequests() {
    requests.removeAll()
  }
  
  public func subscribe(_ updates: @escaping ([UNNotificationRequest]) -> Void) {
    self.publisher = updates
  }
  
}
