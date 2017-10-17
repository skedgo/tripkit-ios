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
  
  fileprivate weak var cardModel: TKUIResultsCardModel!
  
  init(model: TKUIResultsCardModel) {
    self.cardModel = model
    
    super.init()
    
    self.showOverlayPolygon = true
  }
  
  fileprivate var disposeBag = DisposeBag()
  
  fileprivate var routeAnnotations = [MKAnnotation]() {
    didSet {
      mapView?.removeAnnotations(oldValue)
      mapView?.addAnnotations(routeAnnotations)
    }
  }
  
  fileprivate var dropPinRecognizer = UILongPressGestureRecognizer()
  
  override func takeCharge(of mapView: MKMapView, edgePadding: UIEdgeInsets, animated: Bool) {
    super.takeCharge(of: mapView, edgePadding: edgePadding, animated: animated)
    
    // Preparing for route pins
    cardModel.rx_routeBuilder
      .subscribe(onNext: { [weak self] info in
        self?.routeAnnotations = info.annotations
      })
      .disposed(by: disposeBag)
    
    // Long press to drop pin (typically to set origin)
    mapView.addGestureRecognizer(dropPinRecognizer)
    dropPinRecognizer.rx
      .event
      .subscribe(onNext: { [unowned mapView, weak cardModel] recognizer in
        guard recognizer.state == .began else { return }
        let point = recognizer.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        cardModel?.dropPin(at: coordinate)
      })
      .disposed(by: disposeBag)
    
  }
  
  
  override func cleanUp(_ mapView: MKMapView, animated: Bool) {
    disposeBag = DisposeBag()
    
    mapView.removeAnnotations(routeAnnotations)
    routeAnnotations = []
    
    mapView.removeGestureRecognizer(dropPinRecognizer)
    
    super.cleanUp(mapView, animated: animated)
  }
  
  
}

// MARK: - Routing

fileprivate extension TKUIResultsCardModel.RouteBuilder {
  
  var annotations: [MKAnnotation] {
    var annotations = [MKAnnotation]()
    if let origin = origin {
      annotations.append(origin)
    }
    if let destination = destination {
      annotations.append(destination)
    }
    return annotations
  }
  
}

fileprivate extension TKUIResultsMapManager {
  
  
  
}


// MARK: - MKMapViewDelegate

extension TKUIResultsMapManager {
  
  override func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    if annotation === mapView.userLocation {
      return nil // Use the default MKUserLocation annotation
    }
    
    // for whatever reason reuse breaks callouts when remove and re-adding views to change their colours, so we just always create a new one.
    let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
    
    if annotation === cardModel.routeBuilder.origin {
      view.pinTintColor = .green
    } else if annotation === cardModel.routeBuilder.destination {
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

