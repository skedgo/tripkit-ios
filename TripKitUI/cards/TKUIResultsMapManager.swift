//
//  TKUIResultsMapManager.swift
//  TripKit
//
//  Created by Adrian Schoenig on 13/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import RxSwift
import RxCocoa

import TGCardViewController

#if TK_NO_MODULE
#else
  import TripKit
#endif

public protocol TKUIResultsMapManagerType: TGCompatibleMapManager {
  var viewModel: TKUIResultsViewModel? { get set }
  
  var droppedPin: Driver<CLLocationCoordinate2D> { get }
  
  var selectedMapRoute: Driver<TKUIResultsViewModel.MapRouteItem> { get }
}

class TKUIResultsMapManager: TKUIMapManager, TKUIResultsMapManagerType {
  
  weak var viewModel: TKUIResultsViewModel?
  
  override init() {
    super.init()
    
    self.preferredZoomLevel = .road
    self.showOverlayPolygon = true
  }
  
  private var dropPinRecognizer = UILongPressGestureRecognizer()
  private var droppedPinPublisher = PublishSubject<CLLocationCoordinate2D>()
  var droppedPin: Driver<CLLocationCoordinate2D> {
    return droppedPinPublisher.asDriver(onErrorDriveWith: Driver.empty())
  }

  private var tapRecognizer = UITapGestureRecognizer()
  private var selectedRoutePublisher = PublishSubject<TKUIResultsViewModel.MapRouteItem>()
  var selectedMapRoute: Driver<TKUIResultsViewModel.MapRouteItem> {
    return selectedRoutePublisher.asDriver(onErrorDriveWith: Driver.empty())
  }

  private var disposeBag = DisposeBag()
  
  private var originAnnotation: MKAnnotation? {
    didSet {
      if let old = oldValue {
        mapView?.removeAnnotation(old)
      }
      if let new = originAnnotation {
        mapView?.addAnnotation(new)
      }
    }
  }

  private var destinationAnnotation: MKAnnotation? {
    didSet {
      guard let mapView = mapView else { return }
      if let old = oldValue {
        mapView.removeAnnotation(old)
      }
      if let new = destinationAnnotation {
        mapView.addAnnotation(new)
      }
    }
  }
  
  private var selectedRoute: TKUIResultsViewModel.MapRouteItem? {
    didSet {
      // Tell the map to update
      mapView?.setNeedsDisplay()
    }
  }
  
  private var allRoutes: [TKUIResultsViewModel.MapRouteItem] = [] {
    didSet {
      guard let mapView = mapView else { return }
      
      let oldPolylines = oldValue.flatMap { $0.polylines }
      mapView.removeOverlays(oldPolylines)
      
      let newPolylines = allRoutes.flatMap { $0.polylines }
      mapView.addOverlays(newPolylines)
      
      if oldPolylines.isEmpty && !newPolylines.isEmpty {
        // Zoom to the new polylines plus 20% padding around them
        let boundingRect = newPolylines.boundingMapRect
        let zoomToRect = boundingRect.insetBy(dx: boundingRect.size.width * -0.2, dy: boundingRect.size.height * -0.2)
        zoom(to: zoomToRect, animated: true)
      }
    }
  }


  
  override func takeCharge(of mapView: MKMapView, edgePadding: UIEdgeInsets, animated: Bool) {
    super.takeCharge(of: mapView, edgePadding: edgePadding, animated: animated)
    
    guard let viewModel = viewModel else { assertionFailure(); return }
    
    viewModel.originAnnotation
      .drive(onNext: { [weak self] in self?.originAnnotation = $0 })
      .disposed(by: disposeBag)
    
    viewModel.destinationAnnotation
      .drive(onNext: { [weak self] in self?.destinationAnnotation = $0 })
      .disposed(by: disposeBag)
    
    viewModel.mapRoutes
      .drive(onNext: { [weak self] in
        self?.selectedRoute = $1
        self?.allRoutes = $0
      })
      .disposed(by: disposeBag)

    
    // Interaction
    
    mapView.addGestureRecognizer(dropPinRecognizer)
    dropPinRecognizer.rx.event
      .filter { $0.state == .began }
      .map { [unowned mapView] in
        let point = $0.location(in: mapView)
        return mapView.convert(point, toCoordinateFrom: mapView)
      }
      .bind(to: droppedPinPublisher)
      .disposed(by: disposeBag)
    
    mapView.addGestureRecognizer(tapRecognizer)
    tapRecognizer.rx.event
      .filter { $0.state == .ended }
      .filter { [unowned self] _ in !self.allRoutes.isEmpty }
      .map { [unowned mapView] in
        let point = $0.location(in: mapView)
        return mapView.convert(point, toCoordinateFrom: mapView)
      }
      .map { [unowned self] in self.closestRoute(to: $0) }
      .filter { $0 != nil }
      .map { $0! }
      .bind(to: selectedRoutePublisher)
      .disposed(by: disposeBag)
  }
  
  
  override func cleanUp(_ mapView: MKMapView, animated: Bool) {
    disposeBag = DisposeBag()
    
    // clean up map annotations and overlays
    originAnnotation = nil
    destinationAnnotation = nil
    selectedRoute = nil
    allRoutes = []
    
    mapView.removeGestureRecognizer(dropPinRecognizer)
    mapView.removeGestureRecognizer(tapRecognizer)
    
    super.cleanUp(mapView, animated: animated)
  }
  
  private func closestRoute(to coordinate: CLLocationCoordinate2D) -> TKUIResultsViewModel.MapRouteItem? {
    let mapPoint = MKMapPoint(coordinate)
    return allRoutes
      .filter { $0 != selectedRoute }
      .min { $0.distance(to: mapPoint) < $1.distance(to: mapPoint) }
  }
}

extension TKUIResultsViewModel.MapRouteItem {
  fileprivate func distance(to mapPoint: MKMapPoint) -> CLLocationDistance {
    return polylines.map { $0.closestPoint(to: mapPoint).distance }.min() ?? .infinity
  }
}


// MARK: - MKMapViewDelegate

extension TKUIResultsMapManager {
  
  override func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    
    if annotation === mapView.userLocation {
      return nil // Use the default MKUserLocation annotation
    }
    
    // for whatever reason reuse breaks callouts when remove and re-adding views to change their colours, so we just always create a new one.
    let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
    
    if annotation === originAnnotation {
      view.pinTintColor = .green
    } else if annotation === destinationAnnotation {
      view.pinTintColor = .red
    } else {
      view.pinTintColor = .purple
    }
    
    view.animatesDrop = true
    view.isDraggable = true
    
    view.annotation = annotation
    view.alpha = 1
    view.canShowCallout = true
    
    return view
  }
  
  override func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    let renderer = super.mapView(mapView, rendererFor: overlay)
    
    if let routePolyline = overlay as? TKRoutePolyline, let polylineRenderer = renderer as? TKUIPolylineRenderer {
      let isSelected = selectedRoute?.polylines.contains(routePolyline) ?? false
      polylineRenderer.isSelected = isSelected
    }
    
    return renderer
  }
  
}

extension TKUIPolylineRenderer {
  
  var isSelected: Bool {
    get {
      return alpha > 0.9
    }
    set {
      if newValue {
        strokeColor = TKStyleManager.globalTintColor()
        alpha = 1
        lineWidth = 24
      } else {
        strokeColor = TKStyleManager.lightTextColor()
        alpha = 0.3
        lineWidth = 12
      }
    }
  }
  
}
