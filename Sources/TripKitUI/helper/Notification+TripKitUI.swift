//
//  Notification+TripKitUI.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 03.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension Notification.Name {
  
  /// Generic notification about something being updated with real-time data.
  ///
  /// When observing this, you'll want to make sure or at least check that the
  /// notification fired for an object you care about, as there might be a lot
  /// of these notifications.
  ///
  /// This fires on the main thread, i.e., the view context.
  public static let TKUIUpdatedRealTimeData = Notification.Name("TKUIUpdatedRealTimeData")

}
