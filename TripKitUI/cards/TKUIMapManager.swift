//
//  MapManager.swift
//  TripGo
//
//  Created by Adrian Schoenig on 21/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController
import RxSwift
import RxCocoa
import Kingfisher

#if TK_NO_MODULE
#else
  import TripKit
#endif

open class TKUIMapManager: TGMapManager {
  
  /// A factory that all map managers will use as for the default annotations.
  ///
  /// @default: TKUIAnnotationViewBuilder
  public static var annotationBuilderFactory: ((MKAnnotation, MKMapView) -> TKUIAnnotationViewBuilder) = TKUIAnnotationViewBuilder.init
  
  open var showOverlayPolygon = false
  
  fileprivate var heading: CLLocationDirection = 0 {
    didSet {
      guard let mapView = mapView else { return }
      UIView.animate(withDuration: 0.25) {
        for object in mapView.annotations(in: mapView.visibleMapRect) {
          if let annotation = object as? MKAnnotation, let view = mapView.view(for: annotation) {
            TKUIAnnotationViewBuilder.update(annotationView: view, forHeading: self.heading)
          }
        }
      }
    }
  }

  fileprivate let disposeBag = DisposeBag()

  fileprivate var overlayPolygon: MKPolygon? {
    didSet {
      guard oldValue != overlayPolygon else { return }
      removeOverlay(oldValue)
      addOverlay()
    }
  }
  
  override open func takeCharge(of mapView: UIView, edgePadding: UIEdgeInsets, animated: Bool) {
    super.takeCharge(of: mapView, edgePadding: edgePadding, animated: animated)
    
    guard let mapView = mapView as? MKMapView else { preconditionFailure() }

    // Keep heading
    heading = mapView.camera.heading
    
    // Fetching and updating polygons which can be slow
    if let _ = self.overlayPolygon {
      addOverlay()
    }
    
    let updateOverlay = { [weak self] (polygon: MKPolygon?) in
      guard let polygon = polygon else { return }
      self?.overlayPolygon = polygon
    }
    TKRegionOverlayHelper.shared.regionsPolygon(updateOverlay)
    NotificationCenter.default.rx
      .notification(.TKRegionManagerUpdatedRegions)
      .subscribe(onNext: { _ in
        TKRegionOverlayHelper.shared.clearCache()
        TKRegionOverlayHelper.shared.regionsPolygon(updateOverlay)
      })
      .disposed(by: disposeBag)
  }
  
  override open func cleanUp(_ mapView: UIView, animated: Bool) {
    removeOverlay(overlayPolygon)
    
    super.cleanUp(mapView, animated: animated)
  }
  
}

// MARK: - Overlay polygon

extension TKUIMapManager {
  
  private func addOverlay() {
    guard let polygon = overlayPolygon, isActive, showOverlayPolygon else { return }
    mapView?.add(polygon, level: .aboveLabels)
  }
  
  private func removeOverlay(_ polygon: MKPolygon?) {
    guard let polygon = polygon, isActive else { return }
    mapView?.remove(polygon)
  }
  
}

// MARK: - MKMapViewDelegate

extension TKUIMapManager {
  
  open func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
    TKUIMapManagerHelper.adjustZOrder(views)
  }
  
  open func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    if annotation === mapView.userLocation {
      // Use the default MKUserLocation annotation
      return nil
    }
    
    let builder = TKUIMapManager.annotationBuilderFactory(annotation, mapView)
    return builder.build()
  }
  
  open func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    
    if let geodesic = overlay as? MKGeodesicPolyline {
      return TKUIPolylineRenderer(polyline: geodesic)
      
    } else if let polyline = overlay as? TKRoutePolyline {
      let renderer = TKUIPolylineRenderer(polyline: polyline)
      renderer.strokeColor = polyline.route.routeColor
      renderer.lineDashPattern = polyline.route.routeDashPattern
      return renderer
      
    } else if let polygon = overlay as? MKPolygon {
      let renderer = MKPolygonRenderer(polygon: polygon)
      renderer.fillColor = UIColor(red: 52/255, green: 78/255, blue: 109/255, alpha: 0.5)
      renderer.lineWidth = 0
      return renderer
    }
    
    return MKPolygonRenderer(overlay: overlay)
  }
  
  open func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    self.heading = mapView.camera.heading
  }
  
}


