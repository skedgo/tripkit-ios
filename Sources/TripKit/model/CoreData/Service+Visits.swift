//
//  Service+Visits.swift
//  TripKit
//
//  Created by Adrian Schönig on 12/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

extension Service {
  
  public func visit(for stopCode: String) -> StopVisits? {
    guard let visits = visits else { return nil }
    return visits.lazy
      .filter { !($0 is DLSEntry) }
      .first { $0.stop.stopCode == stopCode }
  }
  
  @objc(shapesForEmbarkation:disembarkingAt:)
  public func shapes(embarkation: StopVisits?, disembarkation: StopVisits?) -> [TKDisplayableRoute] {
    var waypoints = [MKAnnotation]()
    var visits = [StopVisits]()
    
    var service: Service? = self
    while let current = service {
      waypoints.append(contentsOf: (current.shape?.sortedCoordinates ?? []))
      visits.append(contentsOf: current.sortedVisits)
      service = disembarkation != nil ? current.continuation : nil
    }
    guard !visits.isEmpty else { return [] }
    
    let startSplit: Int
    if let embarkation = embarkation, embarkation.service == self {
      startSplit = Self.indexForSplitting(waypoints: waypoints, at: embarkation, all: visits)
    } else {
      startSplit = 0
    }
    let endSplit: Int
    if let disembarkation = disembarkation {
      endSplit = Self.indexForSplitting(waypoints: waypoints, at: disembarkation, all: visits)
    } else {
      endSplit = -1
    }
    
    guard startSplit > 0 || endSplit != -1 else {
      return [shape].compactMap { $0 }
    }
    
    var shapes: [TKDisplayableRoute] = []
    shapes.append(TKColoredRoute(
                    path: waypoints,
                    from: 0, to: startSplit + 1,
                    color: .routeDashColorNonTravelled,
                    dashPattern: shape?.routeDashPattern,
                    isTravelled: false))
    
    shapes.append(TKColoredRoute(
                    path: waypoints,
                    from: startSplit, to: endSplit > 0 ? endSplit + 1 : -1,
                    color: color,
                    dashPattern: shape?.routeDashPattern,
                    isTravelled: true))

    if endSplit > 0 {
      shapes.append(TKColoredRoute(
                      path: waypoints,
                      from: endSplit, to: -1,
                      color: .routeDashColorNonTravelled,
                      dashPattern: shape?.routeDashPattern,
                      isTravelled: false))
    }
    return shapes
  }
  
  func buildSortedVisits() -> [StopVisits]? {
    guard let visits = visits, hasServiceData else { return nil }
    
    // avoid duplicate indexes which can happen if we fetched service data
    // multiple times. which shouldn't happen, but even if it does this method
    // should enforce
    var indices = Set<Int16>()
    return visits
      .filter { !($0 is DLSEntry) }
      .filter { indices.insert($0.index).inserted }
      .sorted()
  }
  
  static func indexForSplitting(waypoints: [MKAnnotation], at split: StopVisits, all visits: [StopVisits]) -> Int {
    // where are we in the array?
    var visitsIndex = 0
    var currentVisit = visits[visitsIndex]
    var coordinate = currentVisit.stop.location?.coordinate ?? .invalid
    
    // what is the best index for the current target?
    var best = (distance: CLLocationDistance.infinity, index: -1)

    var index = 0
    while index < waypoints.count {
      let waypoint = waypoints[index]
      let distance = fabs(coordinate.latitude - waypoint.coordinate.latitude) + fabs(coordinate.longitude - waypoint.coordinate.longitude)
      if distance < best.distance {
        // we are moving towards the target
        best = (distance, index)
      }
      
      if best.distance < 0.0001 || index == waypoints.count - 1 {
        // we are at the target. is it the requested split?
        if currentVisit == split {
          return best.index
        } else {
          // advance the target
          visitsIndex += 1
          if visitsIndex >= visits.count {
            return best.index
          }
          currentVisit = visits[visitsIndex]
          coordinate = currentVisit.stop.location?.coordinate ?? .invalid
          let lastBest = best.index
          best = (.infinity, -1)
          index = max(lastBest, 0) // reset to the previous index
          continue
        }
      }
      index += 1
    }
    
    assertionFailure()
    return -1
  }
  
}
