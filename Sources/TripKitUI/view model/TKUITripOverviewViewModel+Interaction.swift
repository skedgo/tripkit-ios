//
//  TKUITripOverviewViewModel+Interaction.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 25/10/2023.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import CoreLocation

import TripKit

extension TKUITripOverviewViewModel {
  static func calculateTripWithStopOver(at coordinate: CLLocationCoordinate2D, trip: Trip) async throws -> TriggerResult {
    let trip = try await TKWaypointRouter.fetchTrip(addingStopOver: coordinate, to: trip)
    return .navigation(.showAlternative(trip))
  }
  

  @available(iOS 14.0, *)
  static func toggleNotifications(enabled: Bool, trip: Trip, includeTimeToLeaveNotification: Bool) async throws -> TriggerResult {
    TKUITripMonitorManager.shared.isTogglingAlert = true
    defer { TKUITripMonitorManager.shared.isTogglingAlert = false }
    
    if enabled {
      if let subscribeURL = trip.subscribeURL {
        // If this fails, it'll abort enabling notifications
        let _ = try await URLSession.shared.data(from: subscribeURL)
      }

      await TKUITripMonitorManager.shared.monitorRegions(from: trip, includeTimeToLeaveNotification: includeTimeToLeaveNotification)
      
    } else {
      if let unsubscribeURL = trip.unsubscribeURL {
        // If this fails, we'll disable the local notifications anyway
        let _ = try? await URLSession.shared.data(from: unsubscribeURL)
      }

      TKUITripMonitorManager.shared.stopMonitoring()
    }
    
    return .success
  }
  
}
