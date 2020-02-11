//
//  TKUIMapManager.swift
//  TripKitUI
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

public protocol TKUIIdentifiableAnnotation: MKAnnotation {
  var identity: String? { get }
}

extension Notification.Name {
  /// User info: ["selection": "identifier" as String]
  public static let TKUIMapManagerSelectionChanged = Notification.Name("TKUIMapManagerSelectionChanged")
}

extension TKNamedCoordinate: TKUIIdentifiableAnnotation {
  public var identity: String? {
    if let stop = self as? TKStopCoordinate {
      return stop.stopCode
    } else if let id = locationID {
      return id
    } else {
      return nil
    }
  }
}

/// The base class for map managers in TripKitUI
///
/// The following diagram illustrates the relationships:
///
/// ```ascii
/// ┌────────────────────────────────────────────────────────────────────┐
/// │ TGCardViewController                                               │
/// │ ┏━━━━━━━━━━━━━━━━━━━┓                   ╔════════════════════════╗ │
/// │ ┃TGMapManager       ┃─ ─ ─Implements ─ ▶║TGCompatibleMapManager  ║ │
/// │ ┗━━━━━━━━━━━━━━━━━━━┛                   ╚════════════════════════╝ │
/// └───────────▲────────────────────────────────────────────────────────┘
///             │
///         Subclass──────────────────┐
///             │                     │
/// ┌───────────┼─────────────────────┼──────────────────────────────────┐
/// │ TripKitUI │                     │                                  │
/// │ ┏━━━━━━━━━━━━━━━━━━━┓ ┏━━━━━━━━━━━━━━━━━━━┓                        │
/// │ ┃TKUIMapManager     ┃ ┃TKUIComposingMap...┃                        │
/// │ ┗━━━━━━━━━━━━━━━━━━━┛ ┗━━━━━━━━━━━━━━━━━━━┛                        │
/// │           ▲                                                        │
/// │       Subclass──────────────────┬─────────────────────┐            │
/// │           │                     │                     │            │
/// │ ┏━━━━━━━━━━━━━━━━━━━┓ ┏━━━━━━━━━━━━━━━━━━━┓ ┏━━━━━━━━━━━━━━━━━━━┓  │
/// │ ┃TKUIServiceMapMa...┃ ┃TKUIRoutingResul...┃ ┃TKUITripMapManager ┃  │
/// │ ┗━━━━━━━━━━━━━━━━━━━┛ ┗━━━━━━━━━━━━━━━━━━━┛ ┗━━━━━━━━━━━━━━━━━━━┛  │
/// └────────────────────────────────────────────────────────────────────┘
/// ```
open class TKUIMapManager: TGMapManager {
  
  /// A factory that all map managers will use as for the default annotations.
  ///
  /// @default: TKUIAnnotationViewBuilder
  public static var annotationBuilderFactory: ((MKAnnotation, MKMapView) -> TKUIAnnotationViewBuilder) = TKUIAnnotationViewBuilder.init
  
  open var showOverlayPolygon = false
  
  /// Cache of renderers, used to update styling when selection changes
  private var renderers: [WeakRenderers] = []
  
  /// The identifier for what should be drawn as selected on the map
  public var selectionIdentifier: String? {
    didSet {
      guard let mapView = mapView else { return }
      
      // this updates the renderers
      renderers.removeAll(where: { $0.renderer == nil })
      renderers.forEach { $0.renderer?.setNeedsDisplay() }
      
      // updates visible views; new views updated from `mapView(_:didAdd:)`
      let views = mapView.annotations(in: mapView.visibleMapRect)
        .compactMap { $0 as? MKAnnotation }
        .compactMap { mapView.view(for: $0) }
      updateAnnotationsViewsForSelection(views)
      
      // give map a chance to itself, if needed (probably not)
      mapView.setNeedsDisplay()
    }
  }
  
  public var selectionMode: TKUIPolylineRenderer.SelectionMode = .thickWithSelectionColor
  
  fileprivate var heading: CLLocationDirection = 0 {
    didSet {
      guard let mapView = mapView else { return }
      UIView.animate(withDuration: 0.25) {
        mapView.annotations(in: mapView.visibleMapRect)
          .compactMap { $0 as? MKAnnotation }
          .compactMap { mapView.view(for: $0) }
          .forEach { TKUIAnnotationViewBuilder.update(annotationView: $0, forHeading: self.heading) }
      }
    }
  }

  fileprivate let disposeBag = DisposeBag()
  private var dynamicDisposeBag: DisposeBag?

  fileprivate var overlayPolygon: MKPolygon? {
    didSet {
      guard oldValue != overlayPolygon else { return }
      removeOverlay(oldValue)
      addOverlay()
    }
  }
  
  public var overlays = [MKOverlay]() {
    didSet {
      mapView?.removeOverlays(oldValue)
      mapView?.addOverlays(overlays, level: .aboveRoads)
    }
  }
  
  /// Annotation that should be animated in and out when appearing and
  /// disappearing. Also, when updating this array, only the differnces will
  /// be animated for any annotations conforming to `TKUIIdentifiableAnnotation`
  public var animatedAnnotations = [MKAnnotation]() {
    didSet {
      guard let mapView = mapView else { return }
      
      let removed = oldValue.elements(notIn: animatedAnnotations)
      let added = animatedAnnotations.elements(notIn: oldValue)
      mapView.addAnnotations(added)
      removeAnnotations(withSameIDsAs: removed)
    }
  }
  
  /// Annotations where each annotation can dynamically change, e.g., changing
  /// its coordinate, title/subtitle, and preferred alpha
  public var dynamicAnnotations = [MKAnnotation]() {
    didSet {
      mapView?.removeAnnotations(oldValue)
      mapView?.addAnnotations(dynamicAnnotations)
      
      if dynamicAnnotations.isEmpty && dynamicDisposeBag != nil {
        dynamicDisposeBag = nil
      } else if !dynamicAnnotations.isEmpty && dynamicDisposeBag == nil {
        startUpdating()
      }
    }
  }
  
  override open func takeCharge(of mapView: MKMapView, edgePadding: UIEdgeInsets, animated: Bool) {
    super.takeCharge(of: mapView, edgePadding: edgePadding, animated: animated)

    // Keep heading
    heading = mapView.camera.heading
    
    // Add content
    mapView.addOverlays(overlays)
    mapView.addAnnotations(animatedAnnotations)
    mapView.addAnnotations(dynamicAnnotations)
    
    if #available(iOS 13.0, *) {
      mapView.pointOfInterestFilter = MKPointOfInterestFilter(excluding: [.publicTransport])
    }
    
    // Fetching and updating polygons which can be slow
    if let _ = self.overlayPolygon {
      addOverlay()
    }
    
    let updateOverlay = { [weak self] (polygon: MKPolygon?) in
      guard let polygon = polygon else { return }
      self?.overlayPolygon = polygon
    }
    TKRegionOverlayHelper.shared.regionsPolygon(completion: updateOverlay)
    NotificationCenter.default.rx
      .notification(.TKRegionManagerUpdatedRegions)
      .subscribe(onNext: { _ in
        TKRegionOverlayHelper.shared.regionsPolygon(forceUpdate: true, completion: updateOverlay)
      })
      .disposed(by: disposeBag)
  }
  
  override open func cleanUp(_ mapView: MKMapView, animated: Bool) {
    removeOverlay(overlayPolygon)
    
    mapView.removeOverlays(overlays)
    mapView.removeAnnotations(dynamicAnnotations)
    removeAnnotations(withSameIDsAs: animatedAnnotations)
    
    super.cleanUp(mapView, animated: animated)
  }
  
  open func annotationBuilder(for annotation: MKAnnotation, in mapView: MKMapView) -> TKUIAnnotationViewBuilder {
    return TKUIMapManager.annotationBuilderFactory(annotation, mapView)
  }
  
}

// MARK: - Overlay polygon

extension TKUIMapManager {
  
  private func addOverlay() {
    guard let polygon = overlayPolygon, isActive, showOverlayPolygon else { return }
    mapView?.addOverlay(polygon, level: .aboveLabels)
  }
  
  private func removeOverlay(_ polygon: MKPolygon?) {
    guard let polygon = polygon, isActive else { return }
    mapView?.removeOverlay(polygon)
  }
  
}

// MARK: - Updating animated annotations

extension TKUIMapManager {
  
  private func removeAnnotations(withSameIDsAs annotations: [MKAnnotation]) {
    guard let mapView = mapView else { return }
    
    // The tricky thing here is this: We can only remove annotations that the
    // map is aware of, i.e., if we have A:[1,2,3] => B:[2,3,4] => C:[3,4,5]
    //
    // When we get to C, we would remove B2, but that never got added to the
    // map, instead the map contains A2. So mapView.remove(B2) will NOT remove
    // A2.
    if !annotations.isEmpty {
      let removedIDs = annotations.identities
      assert(annotations.count == removedIDs.count, "Tried to remove (some) annotations which have no IDs!")
      let annotationsToRemove = mapView.annotations.filter {
        guard let id = ($0 as? TKUIIdentifiableAnnotation)?.identity else { return false }
        return removedIDs.contains(id)
      }
      mapView.removeAnnotations(annotationsToRemove)
    }
  }
  
}

fileprivate extension Array where Element: MKAnnotation {
  var identities: [String] {
    return compactMap { ($0 as? TKUIIdentifiableAnnotation)?.identity }
  }
  
  func elements(notIn other: [Element]) -> [Element] {
    let otherIDs = other.identities
    return filter {
      guard let id = ($0 as? TKUIIdentifiableAnnotation)?.identity else { return true }
      return !otherIDs.contains(id)
    }
  }
}

// MARK: - Updating dynamic annotations

extension TKUIMapManager {
  
  private func startUpdating() {
    let bag = DisposeBag()
    dynamicDisposeBag = bag
    Observable<Int>
      .interval(.seconds(1), scheduler: MainScheduler.instance) // Every second to show live second-based countdown in callout
      .subscribe(onNext: { [unowned self] _ in self.updateDynamicAnnotations(animated: true) })
      .disposed(by: bag)
  }
  
  /// Call this to trigger an update of dynamic annotations, such as real-time
  /// vehicles.
  @objc
  open func updateDynamicAnnotations(animated: Bool = false) {
    guard let mapView = mapView else {
      return
    }
    
    for annotation in dynamicAnnotations {
      if let vehicle = annotation as? Vehicle {
        // Trigger KVO for the sub-title update which has the countdown
        vehicle.setSubtitle(nil)
        
        if let view = mapView.view(for: vehicle) as? TKUIVehicleAnnotationView {
          // Fade in/out according to age
          view.aged(by: CGFloat(vehicle.ageFactor))
          
          // Move vehicle. Temporarily revert to to coordinate based on where
          // the view is, so that we can animate properly to the new view.
          let goodCoordinate = vehicle.coordinate
          let center = CGPoint(x: view.frame.midX, y: view.frame.midY)
          vehicle.setCoordinate(mapView.convert(center, toCoordinateFrom: view.superview))
          UIView.animate(withDuration: animated ? 1 : 0) {
            // now we can animate to the proper coordinate
            vehicle.setCoordinate(goodCoordinate)
            TKUIAnnotationViewBuilder.update(annotationView: view, forHeading: self.heading)
          }
        }
      }
    }
  }
  
}

// MARK: - Updating selected annotations

extension TKUIMapManager {
  
  private func updateAnnotationsViewsForSelection(_ views: [MKAnnotationView]) {
    // update semaphore views - if needed, we could add a more generic
    // way for handling this more like the renderer:
    // 1. Add a `selectionHandler` to TKUIAnnoationViewBuilder
    // 2. Pass that on from there to views that handle it
    // 3. Call `setNeedsDisplay()` here (removing lines marked with *)
    //    and adding instead `.forEach { $0.setNeedsDisplay() }`
    views
      .compactMap { $0 as? TKUISemaphoreView }                   // *
      .forEach { $0.updateSelection(for: selectionIdentifier ) } // *
  }
  
  private func updateSelectionForTapping(_ view: MKAnnotationView) {
    guard
      let displayable = view.annotation as? TKUISemaphoreDisplayable,
      let identifier = displayable.selectionIdentifier
      else { return }
    
    self.selectionIdentifier = identifier
    
    NotificationCenter.default.post(name: .TKUIMapManagerSelectionChanged, object: self, userInfo: ["selection": identifier])
  }
  
}

// MARK: - MKMapViewDelegate

extension TKUIMapManager {
  
  open func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
    TKUIMapManagerHelper.adjustZOrder(views)

    // animations
    let animatedIDs = animatedAnnotations.identities
    let viewsToAnimate = views.filter {
      guard let identity = ($0.annotation as? TKUIIdentifiableAnnotation)?.identity else { return false }
      return animatedIDs.contains(identity)
    }
    for view in viewsToAnimate {
      view.alpha = 0
      let delay = TimeInterval((0...5).randomElement() ?? 0) / 10
      UIView.animate(
        withDuration: 0.25, delay: delay, options: [],
        animations: {
          view.alpha = 1
        }, completion: nil
      )
    }
    
    // the selected view might have been off-screen and was now added
    updateAnnotationsViewsForSelection(views)
  }
  
  open func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    guard annotation !== mapView.userLocation else {
      // Use the default MKUserLocation annotation
      return nil
    }
    
    let builder = annotationBuilder(for: annotation, in: mapView)
    return builder.build()
  }
  
  /// Helper to have weak references for renderers
  private struct WeakRenderers {
    weak var renderer: TKUIPolylineRenderer?
  }
  
  open func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    
    if let geodesic = overlay as? MKGeodesicPolyline {
      return TKUIPolylineRenderer(polyline: geodesic)
      
    } else if let polyline = overlay as? TKRoutePolyline {
      let renderer = TKUIPolylineRenderer(polyline: polyline)
      
      var style = TKUIPolylineRenderer.SelectionStyle.default
      style.defaultColor = polyline.route.routeColor
      style.defaultBorderColor = polyline.route.routeColor?.darker(by: 0.5)
      
      renderer.selectionMode = selectionMode
      renderer.selectionStyle = style
      renderer.lineDashPattern = polyline.route.routeDashPattern
      renderer.selectionIdentifier = polyline.route.routeIsTravelled ? polyline.route.selectionIdentifier : nil
      renderer.selectionHandler = { [weak self] in
        guard let target = self?.selectionIdentifier else { return nil}
        return $0 == target
      }
      
      renderers.append(WeakRenderers(renderer: renderer))
      
      return renderer
      
    } else if let polygon = overlay as? MKPolygon {
      let renderer = MKPolygonRenderer(polygon: polygon)
      renderer.fillColor = .tkMapOverlay
      renderer.lineWidth = 0
      return renderer
    }
    
    return MKPolygonRenderer(overlay: overlay)
  }
  
  open func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    self.heading = mapView.camera.heading
  }
  
  open func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    updateSelectionForTapping(view)
  }
  
}
