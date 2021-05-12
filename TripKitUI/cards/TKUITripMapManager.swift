//
//  TKUITripMapManager.swift
//  TripKitUI
//
//  Created by Adrian Schoenig on 19/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import RxSwift
import TGCardViewController

import TripKit

public protocol TKUITripMapManagerType: TGCompatibleMapManager {}

public class TKUITripMapManager: TKUIMapManager, TKUITripMapManagerType {
  
  private(set) var trip: Trip
  
  private var disposeBag = DisposeBag()
  
  fileprivate weak var selectedSegment: TKSegment? {
    didSet {
      selectionIdentifier = selectedSegment?.selectionIdentifier
    }
  }
  
  override public var annotationsToZoomToOnTakingCharge: [MKAnnotation] {
    return trip.segments.flatMap { $0.annotationsToZoomToOnMap() }
  }
  
  public init(trip: Trip) {
    self.trip = trip
    
    super.init()
    
    self.selectionMode = .regularWithNormalColor
    self.preferredZoomLevel = .road
  }
  
  override public func takeCharge(of mapView: MKMapView, edgePadding: UIEdgeInsets, animated: Bool) {
    super.takeCharge(of: mapView, edgePadding: edgePadding, animated: animated)
    add(trip)
    
    NotificationCenter.default.rx
      .notification(.TKUIUpdatedRealTimeData, object: trip)
      .subscribe(onNext: { [weak self] notification in
        guard
          let self = self,
          let trip = notification.object as? Trip,
          trip == self.trip
          else { return }
        self.updateDynamicAnnotation(trip: trip)
      })
      .disposed(by: disposeBag)
  }
  
  
  public override func cleanUp(_ mapView: MKMapView, animated: Bool) {
    super.cleanUp(mapView, animated: animated)
    
    // Reset the dispose bag, if this is not done, then any observable
    // subscriptions happen during `takeCharge` will trigger multiple
    // times.
    disposeBag = DisposeBag()
  }
  
  override open func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
    TKUIMapManagerHelper.adjustZOrder(views)
    super.mapView(mapView, didAdd: views)
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
    deselectSegment(animated: animated)
    zoom(to: annotationsToZoomToOnTakingCharge, animated: animated)
  }
  
  public func deselectSegment(animated: Bool) {
    self.selectedSegment = nil
  }
  
  public func show(_ segment: TKSegment, animated: Bool, mode: TKUISegmentMode = .onSegment) {
    self.selectedSegment = segment
    
    self.tiles = segment.mapTiles
    
    let annos = segment.annotationsToZoomToOnMap(mode: mode)
    zoom(to: annos, animated: animated)
    
    mapView?.selectAnnotation(segment, animated: animated)
  }
  
  public func refresh(with trip: Trip) {
    self.trip = trip
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
    var overlays = [MKOverlay]()
    var affectedByTraffic = false
    
    for segment in trip.segments {
      annotations.append(contentsOf: TKUIMapManagerHelper.additionalMapAnnotations(for: segment))
      
      // semaphore
      if segment.hasVisibility(.onMap), segment.coordinate.isValid {
        annotations.append(segment)
      }
      
      // shapes (+ visits)
      if let toAdd = TKUIMapManagerHelper.shapeAnnotations(for: segment) {
        annotations += toAdd.points
        overlays += toAdd.overlays
      }
      
      // map style
      affectedByTraffic = affectedByTraffic || segment.isAffectedByTraffic
    }
    
    updateDynamicAnnotation(trip: trip)
    
    mapView?.showsTraffic = affectedByTraffic
    
    let tiles = trip.segments.compactMap(\.mapTiles)
    self.overlayLevel = tiles.isEmpty ? .aboveRoads : .aboveLabels
    
    // If it's a single-modal trip with custom tiles, show them
    if !trip.isMixedModal(ignoreWalking: true), let tiles = tiles.first {
      self.tiles = tiles
    } else {
      self.tiles = nil
    }
    
    self.overlays = TKUIMapManagerHelper.sort(overlays)
    self.annotations = annotations
  }
  
  func updateDynamicAnnotation(trip: Trip) {
    var dynamicAnnotations = [MKAnnotation]()
    
    for segment in trip.segments {
      // Add vehicles
      if let primary = segment.realTimeVehicle {
        assert(primary.managedObjectContext != nil)
        dynamicAnnotations.append(primary)
      }
      dynamicAnnotations.append(contentsOf: segment.realTimeAlternativeVehicles)

      // TODO: add alerts
    }

    if dynamicAnnotations.count != self.dynamicAnnotations.count {
      self.dynamicAnnotations = dynamicAnnotations
    }
  }
  
}
