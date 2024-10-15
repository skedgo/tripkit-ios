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

  static func toggleNotifications(enabled: Bool, trip: Trip, includeTimeToLeaveNotification: Bool) async throws -> TriggerResult {
    TKUITripMonitorManager.shared.isTogglingAlert = true
    defer { TKUITripMonitorManager.shared.isTogglingAlert = false }
    
    if enabled {
      try await TKUITripMonitorManager.shared.monitorRegions(from: trip, includeTimeToLeaveNotification: includeTimeToLeaveNotification)
    } else {
      await TKUITripMonitorManager.shared.stopMonitoring()
    }
    
    return .success
  }
  
}
