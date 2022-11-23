//
//  TKUISimpleHomeMapManager.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 21/11/2022.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import RxCocoa
import RxSwift

import TripKit

class TKUISimpleHomeMapManager: TKUIMapManager {

  private var disposeBag = DisposeBag()

  private var mapRectPublisher = PublishSubject<MKMapRect>()
  private let nextPublisher = PublishSubject<TKUIHomeCard.ComponentAction>()
  
  private var dropPinRecognizer = UILongPressGestureRecognizer()

  override func takeCharge(of mapView: MKMapView, animated: Bool) {
    super.takeCharge(of: mapView, animated: animated)
    
    // Long taps on map drop a pin
    mapView.addGestureRecognizer(dropPinRecognizer)
    
    dropPinRecognizer.rx.event
      .filter { $0.state == .began }
      .compactMap { [unowned mapView, self] event -> TKUIHomeCard.ComponentAction? in
        let point = event.location(in: mapView)
        let mapCoordinate = mapView.convert(point, toCoordinateFrom: mapView)
        return self.next(for: mapCoordinate)
      }
      .subscribe(onNext: { [weak self] next in
        self?.nextPublisher.onNext(next)
      })
      .disposed(by: disposeBag)
  }
  
  override func cleanUp(_ mapView: MKMapView, animated: Bool) {
    // Important to clear these first, before interacting with the map or
    // removing a gesture recogniser, as that can trigger the recogniser by
    // cancelling its touches, which gets `dropPinRecognizer.rx.event` to fire.

    disposeBag = DisposeBag()
    mapView.removeGestureRecognizer(dropPinRecognizer)
    
    super.cleanUp(mapView, animated: animated)
  }
  
  override func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    super.mapView(mapView, regionDidChangeAnimated: animated)

    mapRectPublisher.onNext(mapView.visibleMapRect)
  }
}

extension TKUISimpleHomeMapManager: TKUICompatibleHomeMapManager {
  
  var nextFromMap: Observable<TKUIHomeCard.ComponentAction> {
    nextPublisher.asObservable()
  }

  var mapRect: Driver<MKMapRect> {
    mapRectPublisher.asDriver(onErrorJustReturn: .null)
  }
  
  func zoom(to city: TKRegion.City, animated: Bool) {
    mapView?.setCenter(city.coordinate, animated: animated)
  }
  
  func select(_ annotation: MKAnnotation) {
    mapView?.selectAnnotation(annotation, animated: true)
  }
  
}

// MARK: - Handle pin drop

extension TKUISimpleHomeMapManager {
  
  fileprivate func next(for mapCoordinate: CLLocationCoordinate2D) -> TKUIHomeCard.ComponentAction? {
    guard let annotation = annotation(for: mapCoordinate) else { return nil }
    let routingCard = TKUIRoutingResultsCard(destination: annotation, zoomToDestination: false, initialPosition: .peaking)
    return .push(routingCard)
  }
  
  fileprivate func annotation(for mapCoordinate: CLLocationCoordinate2D) -> MKAnnotation? {
    guard mapCoordinate.isValid else { return nil }
    let annotation = MKPointAnnotation()
    annotation.coordinate = mapCoordinate
    return TKNamedCoordinate.namedCoordinate(for: annotation)
  }
  
}
