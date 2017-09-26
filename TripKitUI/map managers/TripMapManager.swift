//
//  RouteMapManager+Server.swift
//  TripKit
//
//  Created by Adrian Schoenig on 7/09/2016.
//
//

import Foundation
import MapKit

#if TK_NO_MODULE
#else
  import TripKit
#endif


@objc
public enum ZoomMode: Int {
  case zoomOnly
  case addAndZoomToStart
  case addAndZoomToTrip
}

extension TripMapManager {

  @objc
  public func show(_ trip: Trip, zoom: ZoomMode, animated: Bool = false) {
    guard let mapView = mapView() else { return }
    
    // Make sure we don't show that trip already
    guard trip != self.trip || mapView.annotations.isEmpty else { return }
    
    deselectAll()
    self.trip = trip
    
    var forzeZoom = self.forceZoom
    if !forzeZoom
      && mapView.visibleMapRect.origin.x >= 0 // might happen if map view is minimized
    {
      let fromToRect = [trip.request.fromLocation, trip.request.toLocation].mapRect
      forzeZoom = (!MKMapRectIntersectsRect(mapView.visibleMapRect, fromToRect))
    }
    
    // don't force zooma gain
    self.forceZoom = false
    
    let zoomMode = self.forceZoom ? .addAndZoomToTrip : zoom
    refreshRoute(animated: animated, forceRebuild: true, zoom: zoomMode)
  }
  
  @objc
  public func refreshRoute(animated: Bool, forceRebuild force: Bool, zoom: ZoomMode) {
    guard let mapView = mapView(), let trip = self.trip else { return }
    
    if UIDevice.current.userInterfaceIdiom == .phone {
      assert(mapView.delegate === self, "We are not the map view's delegate, but \(String(describing: mapView.delegate)) is.")
    }
    
    if force {
      removeLastRouteFromMap()
      if self.trip == nil {
        return
      }
    }
    
    add(trip, zoom: zoom, animated: animated)
  }
  
  private func add(_ trip: Trip, zoom: ZoomMode = .addAndZoomToTrip, animated: Bool = false) {
    guard let mapView = mapView() else { return }
    
    var zoomTo = [MKAnnotation]()
    var primaries = [Vehicle]()
    var alternatives = [Vehicle]()
    var affectedByTraffic = false
    var alerts = [Alert]()
    
    var addedSegments = 0
    for segment in trip.segments() {
      if (segment as STKDisplayablePoint).pointDisplaysImage {
        if zoom != .zoomOnly {
          add(segment)
        }
        
        // zoom to this segment if we're not in 'zoom to start'
        // mode OR if we're in 'zoom to start' mode and this is
        // near the start
        if zoom != .addAndZoomToStart
          || (segment.order() == .regular && addedSegments < 2)
          || (segment.order() == .end && addedSegments == 1) {
          zoomTo.append(segment)
          addedSegments += 1
        }
        
        guard zoom != .zoomOnly, let toAdd = MapManagerHelper.shapeAnnotations(for: segment) else { continue }

        add(toAdd.points)
        add(toAdd.overlays)
        if toAdd.requestVisits {
          self.requestVisits(for: segment, includeShape: toAdd.overlays.isEmpty)
        }
        
        // vehicles
        if let primary = segment.realTimeVehicle() {
          primaries.append(primary)
        }
        alternatives += segment.realTimeAlternativeVehicles()
        
        // alerts
        let segmentAlerts = segment.alertsWithLocation()
        add(segmentAlerts)
        alerts.append(contentsOf: segmentAlerts)
        
        affectedByTraffic = affectedByTraffic || segment.isAffectedByTraffic()
      }
    }
    
    zoomTo += primaries.map { $0 as MKAnnotation }
    addPrimaryVehicles(primaries, secondaryVehicles: alternatives)
    
    if #available(iOS 9.0, *) {
      mapView.showsTraffic = affectedByTraffic
    }
    
    if zoomTo.count > 0 {
      mapView.zoom(to: zoomTo, edgePadding: delegate()?.mapManagerEdgePadding(self) ?? UIEdgeInsets.zero, animated: animated)
    }
    
    self.alerts = alerts
    
    if zoom != .zoomOnly {
      presentRoute()
    }
    
    // Note: this does not select, but the caller might want to select the main segment
  }
  
  private func requestVisits(for segment: TKSegment, includeShape: Bool) {
    guard
      segment.isPublicTransport(),
      let service = segment.service(),
      let region = segment.startRegion(),
      let departure = segment.departureTime
      else { return }
    
    infoProvider.downloadContent(of: service, forEmbarkationDate: departure, in: region) { [weak self] (updatedService, finished) in
      
      guard let `self` = self else { return }
      guard service == updatedService && finished else { return }
      
      if includeShape, let startCode = segment.scheduledStartStopCode(), let endCode = segment.scheduledEndStopCode() {
        
        
        let start = service.visit(forStopCode: startCode)
        let end = service.visit(forStopCode: endCode)
        for shape in service.shapes(forEmbarkation: start, disembarkingAt: end) {
          self.addShape(shape)
        }
      }
      
      for visit in service.visits ?? [] {
        if segment.shouldShowVisit(visit) {
          self.addAndPresent(visit)
        }
      }
      
    }
  }
  
}
