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

public class TKUITripMapManager: TKUIMapManager {
  
  public let trip: Trip
  
  fileprivate var tripAnnotations = [MKAnnotation]() {
    didSet {
      mapView?.removeAnnotations(oldValue)
      mapView?.addAnnotations(tripAnnotations)
    }
  }
  
  fileprivate var tripOverlays = [MKOverlay]() {
    didSet {
      mapView?.removeOverlays(oldValue)
      mapView?.addOverlays(tripOverlays, level: .aboveRoads)
    }
  }
  
  public init(trip: Trip) {
    self.trip = trip
    
    super.init()
    
    self.preferredZoomLevel = .road
  }
  
  override public func takeCharge(of mapView: UIView, edgePadding: UIEdgeInsets, animated: Bool) {
    super.takeCharge(of: mapView, edgePadding: edgePadding, animated: animated)
    
    add(trip)
  }
  
  override public func cleanUp(_ mapView: UIView, animated: Bool) {
    remove(trip)
    
    super.cleanUp(mapView, animated: animated)
  }
  
  
  public func show(_ segment: TKSegment, animated: Bool) {
    let annos = segment.annotationsToZoomToOnMap()
    zoom(to: annos, animated: animated)
  }
  
}


// MARK: Adding and removing trips from map

private extension TKUITripMapManager {
  
  func add(_ trip: Trip) {
    
    var annotations = [MKAnnotation]()
    var overlays = [MKOverlay]()
    var affectedByTraffic = false
    
    for segment in trip.segments() {
      // We at least add the point for every segment
      guard (segment as STKDisplayablePoint).pointDisplaysImage else { continue }
      annotations.append(segment)
      
      // For non-stationary segments, we also add shape information
      guard !segment.isStationary() else { continue }
      
      guard let toAdd = MapManagerHelper.shapeAnnotations(for: segment) else { continue }
      annotations += toAdd.points
      overlays += toAdd.overlays
      
      // TODO: request visits
      
      // TODO: add vehicles
      
      // TODO: add alerts
      
      affectedByTraffic = affectedByTraffic || segment.isAffectedByTraffic()
    }
    
    mapView?.showsTraffic = affectedByTraffic
    
    tripOverlays = MapManagerHelper.sort(overlays)
    tripAnnotations = annotations
    
  }
  
  func remove(_ trip: Trip) {
    tripOverlays = []
    tripAnnotations = []
  }
  
}
