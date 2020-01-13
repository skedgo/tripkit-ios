//
//  TKUINearbyMapManager.swift
//  TripKitUI
//
//  Created by Adrian Schoenig on 19/5/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import RxSwift
import RxCocoa

public class TKUINearbyMapManager: TKUIMapManager {
  
  public weak var viewModel: TKUINearbyViewModel?
  
  public override init() {
    super.init()
    
    self.preferredZoomLevel = .road
    self.showOverlayPolygon = true
  }
  
  private var mapTrackingPublisher = PublishSubject<MKUserTrackingMode>()
  private var mapRectPublisher = PublishSubject<MKMapRect>()
  
  public var mapCenter: Driver<CLLocationCoordinate2D?> {
    mapRect.map { MKMapRectEqualToRect($0, .null) ? nil : MKCoordinateRegion($0).center }
  }
  
  public var mapRect: Driver<MKMapRect> {
    mapRectPublisher.asDriver(onErrorJustReturn: .null)
  }
  
  private var tapRecognizer = UITapGestureRecognizer()
  private var mapSelectionPublisher = PublishSubject<TKUIIdentifiableAnnotation?>()
  public var mapSelection: Signal<TKUIIdentifiableAnnotation?> {
    return mapSelectionPublisher.asSignal(onErrorJustReturn: nil)
  }
  
  public var searchResult: MKAnnotation? {
    didSet {
      updateSearchResult(searchResult, previous: oldValue)
    }
  }
  
  private var disposeBag = DisposeBag()
  
  override public func takeCharge(of mapView: MKMapView, edgePadding: UIEdgeInsets, animated: Bool) {
    super.takeCharge(of: mapView, edgePadding: edgePadding, animated: animated)
    
    guard let viewModel = viewModel else { assertionFailure(); return }

    // Default content on taking charge
    
    mapView.showsScale = true
    
    let showCurrentLocation = TKLocationManager.shared.authorizationStatus() == .authorized
    mapView.showsUserLocation = showCurrentLocation
    
    if let searchResult = self.searchResult {
      mapView.setUserTrackingMode(.none, animated: animated)
      mapView.addAnnotation(searchResult)
      zoom(to: [searchResult], animated: animated)
    
    } else if let start = viewModel.startLocation {
      mapView.setUserTrackingMode(.none, animated: animated)
      zoom(to: [start], animated: animated)

    } else if showCurrentLocation {
      mapView.setUserTrackingMode(.follow, animated: animated)
    }

    
    // Dynamic content
    
    viewModel.mapAnnotations
      .drive(onNext: { [weak self] annotations in
        guard let self = self else { return }
        self.animatedAnnotations = annotations
      })
      .disposed(by: disposeBag)
    
    viewModel.mapAnnotationToSelect
      .emit(onNext: { [weak self] annotation in
        guard let mapView = self?.mapView else { return }
        guard let onMap = mapView.annotations.first(where: { ($0 as? TKUIIdentifiableAnnotation)?.identity == annotation.identity }) else {
          assertionFailure("We were asked to select annotation with identity \(annotation.identity ?? "nil"), but that hasn't been added to the map. Available: \(mapView.annotations.compactMap { ($0 as? TKUIIdentifiableAnnotation)?.identity }.joined(separator: ", "))")
          return
        }
        
        let alreadySelected = mapView.selectedAnnotations.contains(where: {
          $0.coordinate.latitude == onMap.coordinate.latitude &&
          $0.coordinate.longitude == onMap.coordinate.longitude
        })
        
        if alreadySelected {
          // We deselect the annotation, so mapView(_:didSelect:) can fire if the same
          // one is selected. This closes https://redmine.buzzhives.com/issues/10190.
          mapView.deselectAnnotation(onMap, animated: false)
          
          // We chose not to animate so the annotation appear fixed in place when we
          // deselect and then select.
          mapView.selectAnnotation(onMap, animated: false)
        } else {
          mapView.selectAnnotation(onMap, animated: true)
        }
      })
      .disposed(by: disposeBag)
    
    viewModel.mapOverlays
      .drive(onNext: { [weak self] overlays in
        guard let self = self else { return }
        self.overlays = overlays
      })
      .disposed(by: disposeBag)

    viewModel.searchResultToShow
      .drive(rx.searchResult)
      .disposed(by: disposeBag)
    
    // Action on MKOverlay
    
    mapView.addGestureRecognizer(tapRecognizer)
    tapRecognizer.rx.event
      .filter { $0.state == .ended }
      .compactMap(closestAnnotation)
      .bind(to: mapSelectionPublisher)
      .disposed(by: disposeBag)    
  }
  
  override public func cleanUp(_ mapView: MKMapView, animated: Bool) {
    disposeBag = DisposeBag()
    
    if let searchResult = self.searchResult {
      mapView.removeAnnotation(searchResult)
    }
    
    super.cleanUp(mapView, animated: animated)
  }
  
  private func closestLine(to coordinate: CLLocationCoordinate2D) -> TKRoutePolyline? {
    guard let mapView = self.mapView else { return nil }
    let routes = mapView.overlays.compactMap { $0 as? TKRoutePolyline }
    let mapPoint = MKMapPoint(coordinate)
    return routes.min { $0.distance(to: mapPoint) < $1.distance(to: mapPoint) }
  }
  
  private func closestAnnotation(to tap: UITapGestureRecognizer) -> TKUIIdentifiableAnnotation? {
    guard let mapView = self.mapView else { assertionFailure(); return nil }
    let point = tap.location(in: mapView)
    let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
    guard let line = closestLine(to: coordinate) else { return nil }
    return line.route as? TKUIIdentifiableAnnotation
  }
  
}

extension TKRoutePolyline {
  
  fileprivate func distance(to mapPoint: MKMapPoint) -> CLLocationDistance {
    return closestPoint(to: mapPoint).distance
  }
  
}

extension TKUINearbyMapManager {
  
  public func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
    mapTrackingPublisher.onNext(mode)
  }
  
  public override func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    super.mapView(mapView, regionDidChangeAnimated: animated)

    mapRectPublisher.onNext(mapView.visibleMapRect)
  }
  
  public override func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    super.mapView(mapView, didSelect: view)
    
    guard let identifiable = view.annotation as? TKUIIdentifiableAnnotation else { return }
    mapSelectionPublisher.onNext(identifiable)
  }
  
}

// MARK: Search result

extension Reactive where Base: TKUINearbyMapManager {
  public var searchResult: Binder<MKAnnotation?> {
    return Binder(self.base) { mapManager, annotation in
      mapManager.searchResult = annotation
    }
  }
}


extension TKUINearbyMapManager {
  
  func updateSearchResult(_ annotation: MKAnnotation?, previous: MKAnnotation?) {
    guard let mapView = mapView else { return }
    if let old = previous {
      mapView.removeAnnotation(old)
    }
    if let new = annotation {
      mapView.addAnnotation(new)
      zoom(to: [new], animated: true)
    }
  }
  
}
