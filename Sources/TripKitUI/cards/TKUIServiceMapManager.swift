//
//  TKUIServiceMapManager.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 19.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import RxSwift
import RxCocoa

import TripKit

class TKUIServiceMapManager: TKUIMapManager {
  
  weak var viewModel: TKUIServiceViewModel?
  
  private let disposeBag = DisposeBag()
  
  override init() {
    super.init()
    
    self.preferredZoomLevel = .road
  }
  
  private var embarkation: TKUISemaphoreDisplayable?

  private var disembarkation: TKUISemaphoreDisplayable?
  
  override func takeCharge(of mapView: MKMapView, animated: Bool) {
    super.takeCharge(of: mapView, animated: animated)
    
    guard let viewModel = viewModel else { assertionFailure(); return }
    
//    viewModel.mapContent
//      .drive(onNext: { [weak self] in self?.reloadContent($0) })
//      .disposed(by: disposeBag)
    
    viewModel.selectAnnotation
      .drive(onNext: { [weak self] in self?.select($0) })
      .disposed(by: disposeBag)

    viewModel.realTimeUpdate
      .drive(onNext: { [weak self] update in
        switch update {
        case .updated: self?.updateDynamicAnnotations(animated: true)
        case .idle, .updating: break // nothing to do
        }
      })
      .disposed(by: disposeBag)
  }
  
  override func cleanUp(_ mapView: MKMapView, animated: Bool) {
    clearContent()
    
    super.cleanUp(mapView, animated: animated)
  }
  
  override func updateDynamicAnnotations(animated: Bool) {
    super.updateDynamicAnnotations(animated: animated)
    
    // Also trigger KVO for embarkations
    (embarkation as? TKUIServiceViewModel.ServiceEmbarkation)?.triggerRealTimeKVO()
    (disembarkation as? TKUIServiceViewModel.ServiceEmbarkation)?.triggerRealTimeKVO()
  }
  
  private func select(_ annotation: TKUIIdentifiableAnnotation) {
    guard
      let mapView,
      let match = mapView.annotations.first(where: { ($0 as? TKUIIdentifiableAnnotation)?.identity == annotation.identity })
    else { return }

    self.zoom(to: [match], animated: false) // Not animated, so that we can select
    self.mapView?.selectAnnotation(match, animated: true)
  }

}

// MARK: - Adding the service

extension TKUIServiceMapManager {
  
  private func clearContent() {
    reloadContent(nil)
  }
  
  private func reloadContent(_ content: TKUIServiceViewModel.MapContent?) {
    guard let content = content else {
      self.embarkation = nil
      self.disembarkation = nil
      self.annotations = []
      self.overlays = []
      return
    }
    
    self.embarkation    = content.embarkation
    self.disembarkation = content.disembarkation
    self.annotations    = content.stops.map { $0 as MKAnnotation }
      + [content.embarkation]
      + (content.disembarkation != nil ? [content.disembarkation!] : [])
    self.dynamicAnnotations = content.vehicles
    let polylines = content.shapes.compactMap(TKRoutePolyline.init)
    self.overlays       = polylines
    
    // Zoom to the travelled polylines plus 20% padding around them
    let boundingRect = polylines
      .filter { $0.route.routeIsTravelled }
      .boundingMapRect
    let zoomToRect = boundingRect.insetBy(dx: boundingRect.size.width * -0.2, dy: boundingRect.size.height * -0.2)
    zoom(to: zoomToRect, animated: false)
  }
  
}
