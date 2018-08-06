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
  
  public init(trip: Trip) {
    self.trip = trip
    
    super.init()
    
    self.preferredZoomLevel = .road
  }
  
  override public func takeCharge(of mapView: MKMapView, edgePadding: UIEdgeInsets, animated: Bool) {
    super.takeCharge(of: mapView, edgePadding: edgePadding, animated: animated)
    add(trip)
  }
  
  public func showTrip(animated: Bool) {
    zoom(to: annotations, animated: animated)
  }
  
  public func show(_ segment: TKSegment, animated: Bool) {
    let annos = segment.annotationsToZoomToOnMap()
    zoom(to: annos, animated: animated)
  }
  
}


// MARK: Adding trips to the map

private extension TKUITripMapManager {
  func add(_ trip: Trip) {
    var annotations = [MKAnnotation]()
    var dynamicAnnotations = [MKAnnotation]()
    var overlays = [MKOverlay]()
    var affectedByTraffic = false
    
    for segment in trip.segments() {
      // We at least add the point for every segment
      guard (segment as TKDisplayablePoint).pointDisplaysImage else { continue }
      annotations.append(segment)
      
      // For non-stationary segments, we also add shape information
      guard !segment.isStationary() else { continue }
      
      guard let toAdd = TKUIMapManagerHelper.shapeAnnotations(for: segment) else { continue }
      annotations += toAdd.points
      overlays += toAdd.overlays
      
      // TODO: request visits
      
      // Add vehicles
      if let primary = segment.realTimeVehicle() {
        dynamicAnnotations.append(primary)
      }
      dynamicAnnotations.append(contentsOf: segment.realTimeAlternativeVehicles())
      
      // TODO: add alerts
      
      affectedByTraffic = affectedByTraffic || segment.isAffectedByTraffic()
    }
    
    mapView?.showsTraffic = affectedByTraffic
    
    self.overlays = TKUIMapManagerHelper.sort(overlays)
    self.annotations = annotations
    self.dynamicAnnotations = dynamicAnnotations
  }
}
