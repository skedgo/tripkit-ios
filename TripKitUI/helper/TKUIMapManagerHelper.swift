//
//  TKUIMapManagerHelper.swift
//  TripKitUI
//
//  Created by Adrian Schoenig on 21/4/17.
//
//

import Foundation

import CoreLocation

@available(*, unavailable, renamed: "TKUIMapManagerHelper")
public typealias MapManagerHelper = TKUIMapManagerHelper


public class TKUIMapManagerHelper: NSObject {
  
  private override init() {
    super.init()
  }
  
  @objc(sortOverlays:)
  public static func _objcSort(_ overlays: [MKOverlay]) -> [MKOverlay] {
    return self.sort(overlays)
  }

  public static func sort<T: MKOverlay>(_ overlays: [T]) -> [T] {
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
  
  @objc(adjustZOrderOfAnnotationsViews:)
  public static func adjustZOrder(_ annotationsViews: [MKAnnotationView]) {
    
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
      
      return segmentOne.duration(true) < segmentTwo.duration(true)
    }
    
    sorted.forEach { $0.superview?.bringSubviewToFront($0) }
  }
  
  public static func shapeAnnotations(for segment: TKSegment)
    -> (points: [MKAnnotation], overlays: [MKOverlay], requestVisits: Bool)?
  {
    guard !segment.isStationary else { return nil }
    guard !segment.isFlight else { return geodesicShapeAnnotations(for: segment) }
    
    let shapes = segment.shapes ?? []
    let allEmpty = segment.isPublicTransport && shapes.isEmpty
    
    let overlays = buildOverlaysForShapes(in: segment)
    
    var points = [MKAnnotation]()
    var requestVisits = allEmpty
    
    // Add the visits
    if let service = segment.service {
      if service.hasServiceData {
        let visits = service.visits ?? []
        for visit in visits where segment.shouldShowVisit(visit) {
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
      let polyline = TKRoutePolyline.geodesicPolyline(for: [start, end])
      else { return nil }
      
    return ([], [polyline], false)
  }
  
}

// MARK: - Overlays

extension TKUIMapManagerHelper {
  
  private static func buildOverlaysForShapes(in segment: TKSegment) -> [MKOverlay] {
    guard let shapes = segment.shortedShapes() else { return [] }

    let routes = shapes.reduce(into: [TKColoredRoute]()) { acc, shape in
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
    self.init(path: shape.sortedCoordinates ?? [], color: shape.routeColor, dashPattern: shape.routeDashPattern, isTravelled: shape.routeIsTravelled)
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

