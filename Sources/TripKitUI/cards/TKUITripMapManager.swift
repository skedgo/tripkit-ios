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
import RxCocoa
import TGCardViewController

import TripKit

public protocol TKUITripMapManagerType: TGCompatibleMapManager {}

public class TKUITripMapManager: TKUIMapManager, TKUITripMapManagerType {
  
  private(set) var trip: Trip
  
  private var dropPinRecognizer = UILongPressGestureRecognizer()
  private var droppedPinPublisher = PublishSubject<CLLocationCoordinate2D>()
  var droppedPin: Signal<CLLocationCoordinate2D> {
    return droppedPinPublisher.asAssertingSignal()
  }
  
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
  
  override public func takeCharge(of mapView: MKMapView, animated: Bool) {
    super.takeCharge(of: mapView, animated: animated)
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
    
    // Interaction
    
    mapView.addGestureRecognizer(dropPinRecognizer)
    dropPinRecognizer.rx.event
      .filter { $0.state == .began }
      .compactMap { [unowned mapView] in
        guard TKUITripOverviewCard.config.enableDropToAddStopover else { return nil }
        let point = $0.location(in: mapView)
        return mapView.convert(point, toCoordinateFrom: mapView)
      }
      .bind(to: droppedPinPublisher)
      .disposed(by: disposeBag)
  }
  
  public override func cleanUp(_ mapView: MKMapView, animated: Bool) {
    // Reset the dispose bag, if this is not done, then any observable
    // subscriptions happen during `takeCharge` will trigger multiple
    // times.
    disposeBag = DisposeBag()
    
    mapView.removeGestureRecognizer(dropPinRecognizer)

    super.cleanUp(mapView, animated: animated)
  }
  
  override open func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
    TKUIMapManagerHelper.adjustZOrder(views)
    super.mapView(mapView, didAdd: views)
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
      
      // start/end annotations for the segment itself
      annotations.append(contentsOf: TKUIMapManagerHelper.annotations(for: segment))
      
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
