//
//  TKUITripMapManager.swift
//  TripGo
//
//  Created by Adrian Schoenig on 19/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import TGCardViewController

#if TK_NO_MODULE
#else
  import TripKit
#endif

public protocol TKUITripMapManagerType: TGCompatibleMapManager {}

public class TKUITripMapManager: TKUIMapManager, TKUITripMapManagerType {
  
  public let trip: Trip
  
  fileprivate weak var selectedSegment: TKSegment? {
    didSet {
      // Map style changed, tell it to update
      if let mapView = self.mapView {
        let overlays = mapView.overlays
        mapView.removeOverlays(overlays)
        mapView.addOverlays(overlays)
      }
      mapView?.setNeedsDisplay()
    }
  }
  
  override public var annotationToZoomToOnTakingCharge: [MKAnnotation] {
    return trip.segments.flatMap { $0.annotationsToZoomToOnMap() }
  }
  
  public init(trip: Trip) {
    self.trip = trip
    
    super.init()
    
    self.preferredZoomLevel = .road
    self.styler = TKUITripMapStyler(mapManager: self)
  }
  
  override public func takeCharge(of mapView: MKMapView, edgePadding: UIEdgeInsets, animated: Bool) {
    super.takeCharge(of: mapView, edgePadding: edgePadding, animated: animated)
    add(trip)
  }
  
  override public func annotationBuilder(for annotation: MKAnnotation, in mapView: MKMapView) -> TKUIAnnotationViewBuilder {
    let builder = super.annotationBuilder(for: annotation, in: mapView)
    if let visit = annotation as? StopVisits {
      let isVisited = trip.usesVisit(visit)
      builder.drawCircleAsTravelled(isVisited)
    }
    return builder
  }
  
  public func showTrip(animated: Bool) {
    zoom(to: annotationToZoomToOnTakingCharge, animated: animated)
  }
  
  public func show(_ segment: TKSegment, animated: Bool) {
    self.selectedSegment = segment
    
    let annos = segment.annotationsToZoomToOnMap()
    zoom(to: annos, animated: animated)
  }
  
  public func updateTrip() {
    removeTrip()
    add(trip)
  }
  
}


// MARK: Adding trips to the map

private extension TKUITripMapManager {
  func removeTrip() {
    self.overlays = []
    self.annotations = []
    self.dynamicAnnotations = []
  }
  
  func add(_ trip: Trip) {
    var annotations = [MKAnnotation]()
    var dynamicAnnotations = [MKAnnotation]()
    var overlays = [MKOverlay]()
    var affectedByTraffic = false
    
    for segment in trip.segments {
      // We at least add the point for every segment
      guard (segment as TKUIImageAnnotationDisplayable).pointDisplaysImage else { continue }
      annotations.append(segment)
      
      // For non-stationary segments, we also add shape information
      guard !segment.isStationary else { continue }
      
      guard let toAdd = TKUIMapManagerHelper.shapeAnnotations(for: segment) else { continue }
      annotations += toAdd.points
      overlays += toAdd.overlays
      
      // TODO: request visits
      
      // Add vehicles
      if let primary = segment.realTimeVehicle {
        dynamicAnnotations.append(primary)
      }
      dynamicAnnotations.append(contentsOf: segment.realTimeAlternativeVehicles)
      
      // TODO: add alerts
      
      affectedByTraffic = affectedByTraffic || segment.isAffectedByTraffic
    }
    
    mapView?.showsTraffic = affectedByTraffic
    
    self.overlays = TKUIMapManagerHelper.sort(overlays)
    self.annotations = annotations
    self.dynamicAnnotations = dynamicAnnotations
  }
}

fileprivate struct TKUITripMapStyler: TKUIMapStyler {
  weak var mapManager: TKUITripMapManager?

  func selectionStyle(for overlay: MKOverlay, renderer: TKUIPolylineRenderer) -> TKUIMapSelectionStyle {
    
    guard
      let selectedId = mapManager?.selectedSegment?.templateHashCode
      else { return .none }
    
    guard
      let routePolyline = overlay as? TKRoutePolyline,
      let coloredRoute = routePolyline.route as? TKColoredRoute
      else { return .none }
    
    let isSelected = coloredRoute.identifier == String(selectedId)
    return isSelected ? .selected : .deselected
  }
}
