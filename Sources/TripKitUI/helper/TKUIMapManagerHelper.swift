//
//  TKUIMapManagerHelper.swift
//  TripKitUI
//
//  Created by Adrian Schoenig on 21/4/17.
//
//

import Foundation
import CoreLocation
import MapKit

import TripKit

class TKUIMapManagerHelper: NSObject {
  
  private override init() {
    super.init()
  }
  
  static func sort<T: MKOverlay>(_ overlays: [T]) -> [T] {
    return overlays.sorted { one, two -> Bool in
      
      guard
        let travelledOne = (one as? TKRoutePolyline)?.route.routeIsTravelled,
        let travelledTwo = (two as? TKRoutePolyline)?.route.routeIsTravelled
        else { return true }
      
      if !travelledOne && travelledTwo {
        return true // one before two
      } else {
        return false // one after two
      }
      
    }
    
  }
  
  static func adjustZOrder(_ annotationsViews: [MKAnnotationView]) {
    
    let sorted = annotationsViews.sorted { one, two -> Bool in
      
      guard
        let segmentOne = one.annotation as? TKSegment,
        let segmentTwo = two.annotation as? TKSegment
        else { return true }
      
      switch (segmentOne.isTerminal, segmentTwo.isTerminal) {
      case (true , true ): return false
      case (false, true ): return true
      case (true , false): return false
      case (false, false): break
      }
      
      return segmentOne.duration(includingContinuation: true) < segmentTwo.duration(includingContinuation: true)
    }
    
    sorted.forEach { $0.superview?.bringSubviewToFront($0) }
  }
  
  static func shapeAnnotations(for segment: TKSegment)
    -> (points: [MKAnnotation], overlays: [MKOverlay], requestVisits: Bool)?
  {
    guard !segment.isStationary else { return nil }
    guard !segment.isFlight else { return geodesicShapeAnnotations(for: segment) }
    
    let shapes = segment.shapes
    let allEmpty = segment.isPublicTransport && shapes.isEmpty
    
    let overlays = buildOverlaysForShapes(in: segment)
    
    var points = [MKAnnotation]()
    var requestVisits = allEmpty
    
    // Add the visits
    if let service = segment.service {
      if service.hasServiceData {
        let visits = service.visits ?? []
        for visit in visits where segment.shouldShow(visit) {
          points.append(visit)
        }
      } else {
        requestVisits = true
      }
    }
    
    return (points, overlays, requestVisits)
  }
  
  private static func geodesicShapeAnnotations(for segment: TKSegment)
    -> (points: [MKAnnotation], overlays: [MKOverlay], requestVisits: Bool)?
  {
    guard
      let start = segment.start, let end = segment.end,
      let polyline = TKRoutePolyline.geodesicPolyline(annotations: [start, end])
      else { return nil }
      
    return ([], [polyline], false)
  }
  
  /// Annotations to display for this segment *in addition to* the annotations from the segment itself,
  /// (i.e., in addition to the segment itself as long as its content such as stop visits, alerts and real-time
  /// vehicles). These are typically the query's from and to location if the trip starts away from the query.
  static func additionalMapAnnotations(for segment: TKSegment) -> [MKAnnotation] {
    if segment.order == .start, !segment.matchesQuery(), let from = segment.trip?.request.fromLocation {
      return [TKUIRoutingQueryAnnotation(at: from, isStart: true)]
    } else if segment.order == .end, !segment.matchesQuery(), let to = segment.trip?.request.toLocation {
      return [TKUIRoutingQueryAnnotation(at: to, isStart: false)]
    } else {
      return []
    }
  }
  
}

// MARK: - Overlays

extension TKUIMapManagerHelper {
  
  private static func buildOverlaysForShapes(in segment: TKSegment) -> [MKOverlay] {
    let routes = segment.shapes.reduce(into: [TKColoredRoute]()) { acc, shape in
      if let previous = acc.last, previous.canAbsorb(shape) {
        previous.absorb(shape)
      } else {
        acc.append(TKColoredRoute(shape, in: segment))
      }
    }
    
    return routes.compactMap(TKRoutePolyline.init)
  }
  
}

extension TKColoredRoute {
  
  convenience init(_ shape: Shape, in segment: TKSegment) {
    shape.segment = segment // for better colouring
    let identifier = segment.selectionIdentifier
    let isTravelled = shape.routeIsTravelled
    self.init(path: shape.sortedCoordinates ?? [], color: shape.routeColor, dashPattern: shape.routeDashPattern, isTravelled: isTravelled, identifier: identifier)
  }
  
  func canAbsorb(_ shape: Shape) -> Bool {
    // Could also check last location matches first of route, but we just
    // assume this here
    
    return routeColor == shape.routeColor
        && routeDashPattern == shape.routeDashPattern
        && routeIsTravelled == shape.routeIsTravelled
  }
  
  func absorb(_ shape: Shape) {
    append(shape.sortedCoordinates ?? [])
  }
  
}

