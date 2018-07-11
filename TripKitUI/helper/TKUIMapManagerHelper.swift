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
    
    sorted.forEach { $0.superview?.bringSubview(toFront: $0) }
  }
  
  public static func shapeAnnotations(for segment: TKSegment)
    -> (points: [MKAnnotation], overlays: [MKOverlay], requestVisits: Bool)?
  {
    guard !segment.isStationary()
      else {
        return nil
    }
    
    guard !segment.isFlight() else {
      if
        let start = segment.start,
        let end = segment.end,
        let polyline = TKRoutePolyline.geodesicPolyline(for: [start, end]) {
        
        return ([], [polyline], false)
      } else {
        return nil
      }
    }
    
    let shapes = segment.shapes() ?? []
    let allEmpty = segment.isPublicTransport() && shapes.isEmpty
    
    var points = [MKAnnotation]()
    var overlays = [MKOverlay]()
    var requestVisits = allEmpty
    
    for shape in shapes {
      // Add the shape itself
      shape.segment = segment
      if let overlay = TKRoutePolyline(for: shape) {
        overlays.append(overlay)
      }
      
      // Add the visits
      guard let service = segment.service() else { continue }
      if service.hasServiceData() {
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
  
  
  @objc public static func annotationView(for annotation: MKAnnotation, header: CLLocationDirection) -> MKAnnotationView? {
    
    return nil
    
  }

  
}
