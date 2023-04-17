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
    if segment.isFlight { return geodesicShapeAnnotations(for: segment) }
    
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
          points.append(TKUICircleAnnotation(
            coordinate: visit.coordinate,
            title: visit.title,
            circleColor: service.color ?? .tkAppTintColor,
            isTravelled: segment.uses(visit),
            asLarge: true,
            selectionIdentifier: segment.selectionIdentifier,
            selectionCondition: .ifSelectedOrNoSelection
          ))
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
  
  static func annotations(for segment: TKSegment) -> [MKAnnotation] {
    guard segment.coordinate.isValid else { return [] }
   
    if segment.isStationary {
      // Display these as regular semaphores, but only if this segment is
      // selected on the map.
      return [TKUISemaphoreAnnotation(
        coordinate: segment.coordinate, title: segment.title!,
        image: segment.image, imageURL: segment.imageURL,
        imageIsTemplate: segment.imageIsTemplate,
        semaphoreMode: .headOnly,
        selectionIdentifier: segment.selectionIdentifier,
        selectionCondition: .onlyIfSelected
      )]
      
    } else if segment.hasVisibility(.onMap) {
      
      // This is to get only the *icon* of the destination, could be a car
      // park for driving, or a walking icon for bus.
      var nextMoving = segment.next
      while nextMoving != nil && (nextMoving!.isContinuation || !nextMoving!.hasVisibility(.inDetails)) {
        nextMoving = nextMoving?.next
      }
      
      let nextMode: TKUISemaphoreView.Mode
      if segment.tripSegmentFixedDepartureTime != nil {
        // Arrival time of PT
        nextMode = segment.semaphoreMode(atStart: false)
      } else {
        // Potentially departure time of PT
        nextMode = nextMoving?.semaphoreMode(atStart: true) ?? .headOnly
      }
      
      return [
        // The segment as regular, if selected or nothing selected
        segment,
        
        // Plus the following icon with our arrival time, only if selected
        TKUISemaphoreAnnotation(
          coordinate: segment.end.coordinate,
          image: nextMoving?.image, imageURL: nextMoving?.imageURL,
          imageIsTemplate: nextMoving?.imageIsTemplate ?? false,
          semaphoreMode: nextMode,
          isTerminal: true,
          selectionIdentifier: segment.selectionIdentifier,
          selectionCondition: .onlyIfSelected
        ),
        
        // Plus a circle, but only if something else is selected
        TKUICircleAnnotation(
          coordinate: segment.coordinate,
          circleColor: .tkBackground.withAlphaComponent(0.3),
          isTravelled: true,
          asLarge: true,
          selectionIdentifier: segment.selectionIdentifier,
          selectionCondition: .onlyIfSomethingElseIsSelected
        )
      ]

    } else {
      return []
    }
    
  }
  
}

fileprivate class TKUICircleAnnotation: NSObject, TKUICircleDisplayable, TKUISelectableOnMap {
  internal init(coordinate: CLLocationCoordinate2D, title: String? = nil, circleColor: UIColor, isTravelled: Bool, asLarge: Bool, selectionIdentifier: String?, selectionCondition: TKUISelectionCondition) {
    self.coordinate = coordinate
    self.title = title
    self.circleColor = circleColor
    self.isTravelled = isTravelled
    self.asLarge = asLarge
    self.selectionIdentifier = selectionIdentifier
    self.selectionCondition = selectionCondition

    super.init()
  }
  
  
  // MARK: MKAnnotation
  
  var coordinate: CLLocationCoordinate2D
  var title: String?
  
  // MARK: TKUICircleDisplayable
  
  var circleColor: UIColor
  var isTravelled: Bool
  var asLarge: Bool
  
  // MARK: TKUISelectableOnMap

  var selectionIdentifier: String?
  var selectionCondition: TKUISelectionCondition
  
}

fileprivate class TKUISemaphoreAnnotation: NSObject, TKUISemaphoreDisplayable {
  
  init(coordinate: CLLocationCoordinate2D, title: String? = nil, image: TKImage? = nil, imageURL: URL? = nil, imageIsTemplate: Bool = false, semaphoreMode: TKUISemaphoreView.Mode, bearing: NSNumber? = nil, isTerminal: Bool = false, selectionIdentifier: String?, selectionCondition: TKUISelectionCondition) {
    self.coordinate = coordinate
    self.title = title
    self.image = image
    self.imageURL = imageURL
    self.semaphoreMode = semaphoreMode
    self.bearing = bearing
    self.imageIsTemplate = imageIsTemplate
    self.isTerminal = isTerminal
    self.selectionIdentifier = selectionIdentifier
    self.selectionCondition = selectionCondition
    
    super.init()
  }
  
  
  // MARK: MKAnnotation
  
  var coordinate: CLLocationCoordinate2D
  var title: String?
  
  // MARK: TKUIImageAnnotation
  
  var image: TKImage?
  var imageURL: URL?

  // MARK: TKUISemaphoreDisplayable
  
  var semaphoreMode: TKUISemaphoreView.Mode
  var bearing: NSNumber?
  var imageIsTemplate: Bool
  var isTerminal: Bool
  
  // MARK: TKUISelectableOnMap

  var selectionIdentifier: String?
  var selectionCondition: TKUISelectionCondition

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

