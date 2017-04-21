//
//  MapManagerHelper.swift
//  TripKitUI
//
//  Created by Adrian Schoenig on 21/4/17.
//
//

import Foundation

import CoreLocation

public class MapManagerHelper: NSObject {
  
  @objc
  public static func sort(_ overlays: [MKOverlay]) -> [MKOverlay] {
    
    return overlays.sorted { one, two -> Bool in
      
      guard
        let travelledOne = (one as? STKRoutePolyline)?.route.routeIsTravelled?(),
        let travelledTwo = (two as? STKRoutePolyline)?.route.routeIsTravelled?()
        else { return true }
      
      if !travelledOne && travelledTwo {
        return true // one before two
      } else {
        return false // one after two
      }
      
    }
    
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
        let polyline = STKRoutePolyline.geodesicPolyline(for: [start, end]) {
        
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
      if let overlay = STKRoutePolyline(for: shape) {
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
  
  
  public static func annotationView(for annotation: MKAnnotation, header: CLLocationDirection) -> MKAnnotationView? {
    
    return nil
    
  }

  
}
