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
  static func calculateTripWithStopOver(at coordinate: CLLocationCoordinate2D, trip: Trip) async throws -> TriggerResult? {
    let trip = try await TKWaypointRouter.fetchTrip(addingStopOver: coordinate, to: trip)
    return .navigation(.showAlternative(trip))
  }
  

  @available(iOS 14.0, *)
  static func toggleNotifications(enabled: Bool, trip: Trip, includeTimeToLeaveNotification: Bool) async -> TriggerResult {
    if enabled {
      if let subscribeURL = trip.subscribeURL {
        let _ = try? await URLSession.shared.data(from: subscribeURL)
      }

      await TKUITripMonitorManager.shared.monitorRegions(from: trip, includeTimeToLeaveNotification: includeTimeToLeaveNotification)
      
    } else {
      if let unsubscribeURL = trip.unsubscribeURL {
        let _ = try? await URLSession.shared.data(from: unsubscribeURL)
      }

      TKUITripMonitorManager.shared.stopMonitoring()
    }
    
    return .success
  }
  
}
