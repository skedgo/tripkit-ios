//
//  TripRequest.swift
//  Pods
//
//  Created by Adrian Schoenig on 18/11/16.
//
//

import Foundation

extension TripRequest {
 
  public func determineRegions() -> [SVKRegion] {
    let start = self.fromLocation.coordinate
    let end = self.toLocation.coordinate
    return SVKRegionManager.sharedInstance().localRegions(start: start, end: end)
  }
  
  /// The primary alternatives for this request, which is constructed by
  /// taking the trip groups, sorting them by the user's selected sort
  /// orders, and then taking each group's visible trip.
  ///
  /// - SeeAlso: `sortDescriptorsAccordingToSelectedOrder`
  ///
  /// - Returns: Visible trip for each trip group sorted by user's preferences
  public func sortedVisibleTrips() -> [Trip] {
    guard let set = self.tripGroups as NSSet? else { return [] }
    
    let sorters = sortDescriptorsAccordingToSelectedOrder()
    guard let sorted = set.sortedArray(using: sorters) as? [TripGroup] else {
      preconditionFailure()
    }
    
    return sorted
      .filter { $0.visibility != .hidden }
      .flatMap { $0.visibleTrip }
  }
  
}
