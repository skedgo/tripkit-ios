//
//  ViewController.swift
//  MiniMap
//
//  Created by Adrian Schoenig on 7/7/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import AppKit
import MapKit

import TripKit

class ViewController: NSViewController {

  @IBOutlet weak var mapView: MKMapView!
  
  var from: MKAnnotation? = nil
  var to: MKAnnotation? = nil
  
  let router = TKRouter(config: .userSettings())
  
  override func viewDidLoad() {
    super.viewDidLoad()

    let presser = NSPressGestureRecognizer(target: self, action: #selector(pressTriggered))
    presser.minimumPressDuration = 1
    mapView.addGestureRecognizer(presser)
  }

  override var representedObject: Any? {
    didSet {
    // Update the view, if already loaded.
    }
  }

  @objc
  func pressTriggered(_ recognizer: NSPressGestureRecognizer) {
    guard recognizer.state == .began else { return }
    
    let isFrom = from == nil

    let point: NSPoint = recognizer.location(in: mapView)
    let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
    
    let annotation = MKPointAnnotation()
    annotation.coordinate = coordinate
    annotation.title = isFrom ? "Start" : "End"
    
    if isFrom {
      if let oldFrom = from {
        mapView.removeAnnotation(oldFrom)
      }
      from = annotation
    } else {
      if let oldTo = to {
        mapView.removeAnnotation(oldTo)
      }
      to = annotation
    }
    
    mapView.addAnnotation(annotation)
    
    route()
  }
  
  func route() {
    guard let from = from, let to = to else { return }
    
    router.modeIdentifiers = [
      TKTransportMode.publicTransport.modeIdentifier
    ]
    
    let query = TKRoutingQuery(
      from: from, to: to, at: .leaveASAP, modes: [
      "pt_pub"], context: TripKit.shared.tripKitContext
    )
    
    router.fetchBestTrip(for: query) { result in
      switch result {
      case .success(let trip):
        for segment in trip.segments {
          guard segment.hasVisibility(.onMap) else { continue }
          self.mapView.addAnnotation(segment)
          for shape in segment.shapes {
            guard let polyline = TKRoutePolyline(route: shape) else { continue }
            self.mapView.addOverlay(polyline)
          }
        }
      case .failure(let error):
        print("Error \(error)")
      }
    }
  }

}

extension ViewController: MKMapViewDelegate {
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    let pinView: MKPinAnnotationView
    if let reused = mapView.dequeueReusableAnnotationView(withIdentifier: "pinView") as? MKPinAnnotationView {
      reused.annotation = annotation
      pinView = reused
    } else {
      pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pinView")
    }

    pinView.animatesDrop = true
    pinView.isDraggable = true
    pinView.pinTintColor = annotation.title! == "Start" ? .green : .red
    pinView.canShowCallout = true
    return pinView
  }
  
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if let polyline = overlay as? TKRoutePolyline {
      let renderer = MKPolylineRenderer(polyline: polyline)
      renderer.lineWidth = 10
      renderer.strokeColor = polyline.route.routeColor
      return renderer
    } else {
      return MKOverlayRenderer(overlay: overlay)
    }
  }
  
}
