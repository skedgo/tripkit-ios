//
//  TKUIMapManager.swift
//  TripKitUI
//
//  Created by Adrian Schoenig on 21/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit
import UIKit

import TGCardViewController
import RxSwift
import RxCocoa
import Kingfisher

import TripKit

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
  /// - default: TKUIAnnotationViewBuilder
  public static var annotationBuilderFactory: ((MKAnnotation, MKMapView) -> TKUIAnnotationViewBuilder) = TKUIAnnotationViewBuilder.init
  
  /// The POI categories from Apple Maps to never show on the map, e.g., as they are added separately.
  public static var pointsOfInterestsToExclude: [MKPointOfInterestCategory] = [.publicTransport]
  
  static var tileOverlays: [String: MKTileOverlay] = [:]
  
  /// Callback that fires when attributions need to be displayed. In particular when using `tiles`.
  public var attributionDisplayer: (([TKAPI.DataAttribution], _ sender: UIView) -> Void)? = nil
  
  /// Whether to show the coverage polygon which greys out areas outside the coverage
  open var showOverlayPolygon = false
  
  /// Tiles to use instead of Apple Maps tiles
  var tiles: TKUIMapTiles? = nil {
    didSet {
      guard tiles?.id != oldValue?.id else { return }
      
      // clean up, including attribution
      if let previous = tileOverlay {
        mapView?.removeOverlay(previous)
        tileOverlay = nil
      }
      if let mapView {
        if let settingsToRestore {
          restore(settingsToRestore, on: mapView)
        } else {
          cleanUpAttributionView(from: mapView)
        }
        self.settingsToRestore = nil
      }
      
      // add new content
      if let tiles {
        tileOverlay = buildTileOverlay(tiles: tiles)

        if let mapView, let tileOverlay {
          settingsToRestore = accommodateTileOverlay(tileOverlay, sources: tiles.sources, on: mapView)
        }
      }
      
      // update the renderers
      updateOverlays(updateMode: .updateDashPatterns)
    }
  }
  
  private var tileOverlay: MKTileOverlay?
  private var settingsToRestore: TKUIMapSettings?
  
  /// Cache of renderers, used to update styling when selection changes
  private var renderers: [WeakRenderers] = []
  
  /// Whether user interaction for selecting annotation is enabled, defaults to `true`.
  open var annotationSelectionEnabled: Bool = true {
    didSet {
      if !annotationSelectionEnabled {
        selectionIdentifier = nil
      }
    }
  }
  
  /// The identifier for what should be drawn as selected on the map
  public var selectionIdentifier: String? {
    didSet {
      updateOverlays(updateMode: .updateSelection)
    }
  }
  
  public var selectionMode: TKUIPolylineRenderer.SelectionMode = .thickWithSelectionColor
  
  fileprivate var heading: CLLocationDirection = 0

  fileprivate let disposeBag = DisposeBag()
  private var dynamicDisposeBag: DisposeBag?

  /// The level for adding regular overlays. Note that any tile overlays will have `.aboveRoads`, so if you will use tile overlays
  /// *and* regular overlays better to set this to `.aboveLabels`.
  var overlayLevel: MKOverlayLevel = .aboveRoads

  fileprivate var overlayPolygon: MKPolygon? {
    didSet {
      guard oldValue != overlayPolygon else { return }
      removeOverlay(oldValue)
      addOverlay()
    }
  }
  
  /// Overlays on the map, which are typically routes in TripKit
  ///
  /// As soon as you set this, the routes will be added to the map.
  public var overlays = [MKOverlay]() {
    didSet {
      mapView?.removeOverlays(oldValue)
      mapView?.addOverlays(overlays, level: overlayLevel)
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
  
  override open func takeCharge(of mapView: MKMapView, animated: Bool) {
    super.takeCharge(of: mapView, animated: animated)

    // Keep heading
    heading = mapView.camera.heading
    
    mapView.pointOfInterestFilter = MKPointOfInterestFilter(excluding: TKUIMapManager.pointsOfInterestsToExclude)

    // Add content
    mapView.addOverlays(overlays, level: overlayLevel)
    mapView.addAnnotations(animatedAnnotations)
    mapView.addAnnotations(dynamicAnnotations)
    if let overlay = self.tileOverlay, let tiles = self.tiles {
      settingsToRestore = self.accommodateTileOverlay(overlay, sources: tiles.sources, on: mapView)
    }
    
    // Fetching and updating polygons which can be slow
    if let _ = self.overlayPolygon {
      addOverlay()
    }
    
    let updateOverlay = { [weak self] (polygon: MKPolygon?) -> Void in
      self?.overlayPolygon = polygon
    }
    TKRegionOverlayHelper.shared.regionsPolygon(completion: updateOverlay)
    NotificationCenter.default.rx
      .notification(.TKRegionManagerUpdatedRegions)
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { _ in
        TKRegionOverlayHelper.shared.regionsPolygon(forceUpdate: true, completion: updateOverlay)
      })
      .disposed(by: disposeBag)
  }
  
  override open func cleanUp(_ mapView: MKMapView, animated: Bool) {
    removeOverlay(overlayPolygon)
    
    if let tileOverlay = self.tileOverlay {
      mapView.removeOverlay(tileOverlay)
      // When we have custom map title, we also add an attribution view. We need to
      // remove this when the map manager is asked to clean up, otherwise, the
      // attribution view will go side-by-side with the Apple Map attribution.
      // See https://redmine.buzzhives.com/issues/15942
      if let attribution = mapView.subviews.first(where: { $0 is TKUIAttributionView }) {
        attribution.removeFromSuperview()
      }
    }
    if let toRestore = settingsToRestore {
      self.restore(toRestore, on: mapView)
      settingsToRestore = nil
    } else {
      self.cleanUpAttributionView(from: mapView)
    }

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
    
    let vehicles = dynamicAnnotations
      .compactMap { $0 as? Vehicle }
      .filter { $0.managedObjectContext != nil }
    
    for vehicle in vehicles {
      // Trigger KVO for the sub-title update which has the countdown
      vehicle.triggerRealTimeKVO()
      
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

// MARK: - Updating selected annotations

extension TKUIMapManager {
  
  private func updateAnnotationsViewsForSelection(_ views: [MKAnnotationView]) {
    // update semaphore views - if needed, we could add a more generic
    // way for handling this more like the renderer:
    // 1. Add a `selectionHandler` to TKUIAnnoationViewBuilder
    // 2. Pass that on from there to views that handle it
    // 3. Call `setNeedsDisplay()` here (removing the line marked with *)
    //    and adding instead `.forEach { $0.setNeedsDisplay() }`
    views
      .forEach { $0.updateSelection(for: selectionIdentifier ) } // *
  }
  
  private func updateSelectionForTapping(_ view: MKAnnotationView) {
    guard
      annotationSelectionEnabled,
      let selectable = view.annotation as? TKUISelectableOnMap,
      let identifier = selectable.selectionIdentifier
      else { return }
    
    self.selectionIdentifier = identifier
    
    NotificationCenter.default.post(name: .TKUIMapManagerSelectionChanged, object: self, userInfo: ["selection": identifier])
  }
  
}

// MARK: - MKMapViewDelegate

extension TKUIMapManager {
  
  /// Helper to have weak references for renderers
  private struct WeakRenderers {
    weak var renderer: TKUIPolylineRenderer?
    var routeDashPattern: [NSNumber]?
  }
  
  private enum UpdateMode {
    case updateSelection
    case updateDashPatterns
  }
  
  private func updateOverlays(updateMode: UpdateMode) {
    guard let mapView else { return }
    
    // this updates the renderers
    renderers.removeAll(where: { $0.renderer == nil })
    
    switch updateMode {
    case .updateSelection:
      // updates existing views; new views updated from `mapView(_:didAdd:)`
      let views = mapView.annotations
        .compactMap { mapView.view(for: $0) }
      updateAnnotationsViewsForSelection(views)
    
    case .updateDashPatterns:
      renderers.forEach {
        guard let renderer = $0.renderer else { return }
        Self.style(
          renderer: renderer,
          onOverlay: tileOverlay != nil,
          dashPattern: $0.routeDashPattern
        )
      }
    }
    
    renderers.forEach { $0.renderer?.setNeedsDisplay() }
    
    // give map a chance to itself, if needed (probably not)
    mapView.setNeedsDisplay()
  }
  
  open func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
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
  
  open func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    
    if let geodesic = overlay as? MKGeodesicPolyline {
      return TKUIPolylineRenderer(polyline: geodesic)
      
    } else if let polyline = overlay as? TKRoutePolyline {
      let renderer = TKUIPolylineRenderer(polyline: polyline)
      
      var style = TKUIPolylineRenderer.SelectionStyle.default
      style.defaultColor = polyline.route.routeColor
      style.defaultBorderColor = polyline.route.routeColor?.darker(by: 0.5)
      style.deselectedColor = style.defaultColor ?? style.deselectedColor
      style.deselectedBorderColor = style.defaultBorderColor ?? style.deselectedBorderColor
      
      renderer.selectionMode = selectionMode
      renderer.selectionStyle = style
      renderer.selectionIdentifier = polyline.route.routeIsTravelled ? polyline.route.selectionIdentifier : nil
      renderer.selectionHandler = { [weak self] in
        guard let target = self?.selectionIdentifier else { return nil }
        return $0 == target
      }
      
      Self.style(
        renderer: renderer,
        onOverlay: tileOverlay != nil,
        dashPattern: polyline.route.routeDashPattern
      )
      
      renderers.append(WeakRenderers(renderer: renderer, routeDashPattern: polyline.route.routeDashPattern))
      
      return renderer
      
    } else if let polygon = overlay as? MKPolygon {
      let renderer = MKPolygonRenderer(polygon: polygon)
      renderer.fillColor = .tkMapOverlay
      renderer.lineWidth = 0
      return renderer
    
    } else if let tileOverlay = overlay as? MKTileOverlay {
      return MKTileOverlayRenderer(tileOverlay: tileOverlay)
    }
    
    return MKPolygonRenderer(overlay: overlay)
  }
  
  private static func style(renderer: TKUIPolylineRenderer, onOverlay: Bool, dashPattern: [NSNumber]?) {
    renderer.lineCap = onOverlay ? .round : .square
    renderer.lineDashPattern = onOverlay ? [10, 15] : dashPattern
    renderer.fillDashBackground = !onOverlay
  }
  
  open func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    let newHeading = mapView.camera.heading
    guard abs(newHeading - self.heading) > 5 else { return }
    
    self.heading = newHeading
    
    let annotationViews = mapView.annotations(in: mapView.visibleMapRect)
      .compactMap { $0 as? MKAnnotation }
      .compactMap { mapView.view(for: $0) }
    guard !annotationViews.isEmpty else { return }
    
    if animated {
      UIView.animate(withDuration: 0.25) {
        for view in annotationViews {
          TKUIAnnotationViewBuilder.update(annotationView: view, forHeading: newHeading)
        }
      }

    } else {
      for view in annotationViews {
        TKUIAnnotationViewBuilder.update(annotationView: view, forHeading: newHeading)
      }
    }
  }
  
  open func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    updateSelectionForTapping(view)
  }
  
}
