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

class TKUIResultsMapManager: TKUIMapManager {
  
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
      if let old = oldValue {
        mapView?.removeAnnotation(old)
      }
      if let new = originAnnotation {
        mapView?.addAnnotation(new)
      }
    }
  }

  
  override func takeCharge(of mapView: UIView, edgePadding: UIEdgeInsets, animated: Bool) {
    super.takeCharge(of: mapView, edgePadding: edgePadding, animated: animated)
    
    guard let mapView = mapView as? MKMapView else { preconditionFailure() }
    guard let viewModel = viewModel else { assertionFailure(); return }
    
    // Preparing for route pins
    viewModel.originAnnotation
      .drive(onNext: { [weak self] in self?.originAnnotation = $0 })
      .disposed(by: disposeBag)
    
    viewModel.destinationAnnotation
      .drive(onNext: { [weak self] in self?.destinationAnnotation = $0 })
      .disposed(by: disposeBag)

    
    // Long press to drop pin (typically to set origin)
    mapView.addGestureRecognizer(dropPinRecognizer)
    dropPinRecognizer.rx.event
      .filter { $0.state == .began }
      .map { [unowned mapView] in
        let point = $0.location(in: mapView)
        return mapView.convert(point, toCoordinateFrom: mapView)
      }
      .bind(to: droppedPinPublisher)
      .disposed(by: disposeBag)
  }
  
  
  override func cleanUp(_ mapView: UIView, animated: Bool) {
    guard let mapView = mapView as? MKMapView else { preconditionFailure() }
    disposeBag = DisposeBag()
    
    originAnnotation = nil
    destinationAnnotation = nil
    
    mapView.removeGestureRecognizer(dropPinRecognizer)
    
    super.cleanUp(mapView, animated: animated)
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
  
}
