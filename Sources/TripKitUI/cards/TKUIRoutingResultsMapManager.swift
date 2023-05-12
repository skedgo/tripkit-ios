//
//  TKUIRoutingResultsMapManager.swift
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

import TripKit

/// An item to be displayed on the map
public struct TKUIRoutingResultsMapRouteItem {
  let trip: Trip
  
  public let polyline: TKRoutePolyline
  public let selectionIdentifier: String
  
  init?(_ trip: Trip) {
    self.trip = trip
    self.selectionIdentifier = trip.objectID.uriRepresentation().absoluteString
    
    let displayableShapes = trip.segments
      .compactMap { $0.shapes.isEmpty ? nil : $0.shapes }   // Only include those with shapes
      .flatMap { $0.filter { $0.routeIsTravelled } } // Flat list of travelled shapes
    
    let route = displayableShapes
      .reduce(into: TKColoredRoute(path: [], identifier: selectionIdentifier)) { $0.append($1.sortedCoordinates ?? []) }
    
    guard let polyline = TKRoutePolyline(route: route) else { return nil }
    self.polyline = polyline
  }
}

public protocol TKUIRoutingResultsMapManagerType: TGCompatibleMapManager {
  @MainActor
  var droppedPin: Signal<CLLocationCoordinate2D> { get }
  
  @MainActor
  var selectedMapRoute: Signal<TKUIRoutingResultsMapRouteItem> { get }
}

class TKUIRoutingResultsMapManager: TKUIMapManager, TKUIRoutingResultsMapManagerType {
  
  weak var viewModel: TKUIRoutingResultsViewModel?
  
  private let zoomToDestination: Bool
  
  init(destination: MKAnnotation? = nil, zoomToDestination: Bool) {
    self.zoomToDestination = zoomToDestination

    super.init()

    self.destinationAnnotation = destination
    self.preferredZoomLevel = .road
    self.showOverlayPolygon = true
  }
  
  private var dropPinRecognizer = UILongPressGestureRecognizer()
  private var droppedPinPublisher = PublishSubject<CLLocationCoordinate2D>()
  var droppedPin: Signal<CLLocationCoordinate2D> {
    return droppedPinPublisher.asSignal(onErrorSignalWith: .empty())
  }

  private var tapRecognizer = UITapGestureRecognizer()
  private var selectedRoutePublisher = PublishSubject<TKUIRoutingResultsMapRouteItem>()
  var selectedMapRoute: Signal<TKUIRoutingResultsMapRouteItem> {
    return selectedRoutePublisher.asSignal(onErrorSignalWith: .empty())
  }
  
  private var tappedPinPublisher = PublishSubject<(MKAnnotation, TKUIRoutingResultsViewModel.SearchMode?)>()
  var tappedPin: Signal<(MKAnnotation, TKUIRoutingResultsViewModel.SearchMode?)> {
    return tappedPinPublisher.asSignal(onErrorSignalWith: .empty())
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
  
  fileprivate var selectedRoute: TKUIRoutingResultsMapRouteItem? {
    didSet {
      selectionIdentifier = selectedRoute?.selectionIdentifier
    }
  }
  
  private var allRoutes: [TKUIRoutingResultsMapRouteItem] = [] {
    didSet {
      guard let mapView = mapView else { return }
      
      let oldPolylines = oldValue.map { $0.polyline }
      mapView.removeOverlays(oldPolylines)
      
      let newPolylines = allRoutes.map { $0.polyline }
      mapView.addOverlays(newPolylines)
      
      if oldPolylines.isEmpty && !newPolylines.isEmpty {
        // Zoom to the new polylines plus 20% padding around them
        let boundingRect = newPolylines.boundingMapRect
        let zoomToRect = boundingRect.insetBy(dx: boundingRect.size.width * -0.2, dy: boundingRect.size.height * -0.2)
        zoom(to: zoomToRect, animated: true)
      }
    }
  }

  
  override func takeCharge(of mapView: MKMapView, animated: Bool) {
    super.takeCharge(of: mapView, animated: animated)
    
    guard let viewModel else { assertionFailure(); return }
    
    let zoomTo = [originAnnotation, destinationAnnotation].compactMap { $0 }
    if zoomToDestination, !zoomTo.isEmpty {
      self.zoom(to: zoomTo, animated: animated)
    }
    
    viewModel.originAnnotation
      .drive(onNext: { [weak self] annotation, select in
        guard let self else { return }
        self.originAnnotation = annotation
        if select, let annotation {
          self.mapView?.selectAnnotation(annotation, animated: true)
        }
      })
      .disposed(by: disposeBag)
    
    viewModel.destinationAnnotation
      .drive(onNext: { [weak self] annotation, select in
        guard let self else { return }
        self.destinationAnnotation = annotation
        if select, let annotation {
          self.mapView?.selectAnnotation(annotation, animated: true)
        }
      })
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
  
  private func closestRoute(to coordinate: CLLocationCoordinate2D) -> TKUIRoutingResultsMapRouteItem? {
    let mapPoint = MKMapPoint(coordinate)
    return allRoutes
      .filter { $0 != selectedRoute }
      .min { $0.distance(to: mapPoint) < $1.distance(to: mapPoint) }
  }
}

extension TKUIRoutingResultsMapRouteItem {
  fileprivate func distance(to mapPoint: MKMapPoint) -> CLLocationDistance {
    return polyline.closestPoint(to: mapPoint).distance
  }
}


// MARK: - MKMapViewDelegate

extension TKUIRoutingResultsMapManager {
  
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
    
    if TKUICustomization.shared.locationInfoTapHandler != nil {
      let button = UIButton(type: .detailDisclosure)
      button.tintColor = TKStyleManager.globalTintColor
      view.rightCalloutAccessoryView = button
    } else {
      view.rightCalloutAccessoryView = nil
    }
    
    return view
  }
  
  func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    guard let annotation = view.annotation else { return assertionFailure() }
    
    let mode: TKUIRoutingResultsViewModel.SearchMode?
    if annotation === originAnnotation {
      mode = .origin
    } else if annotation === destinationAnnotation {
      mode = .destination
    } else {
      mode = .none
    }
    tappedPinPublisher.onNext((annotation, mode))
  }
  
}
