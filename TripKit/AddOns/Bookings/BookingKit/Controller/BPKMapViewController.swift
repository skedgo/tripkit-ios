//
//  BPKMapViewController.swift
//  TripKit
//
//  Created by Adrian Schoenig on 12/08/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import MapKit

public class BPKMapViewController: UIViewController {
  
  @objc weak var mapView: MKMapView!
  
  @objc public var annotation: MKAnnotation? {
    didSet {
      showAnnotation(true)
    }
  }
  
  override public func viewDidLoad() {
    super.viewDidLoad()
    
    let mapView = MKMapView(frame: view.frame)
    mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(mapView)
    self.mapView = mapView
    
    showAnnotation(false)
  }
  
  private func showAnnotation(_ animated: Bool) {
    if let annotation = annotation,
      let mapView = mapView {
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(annotation)
        
        let camera = MKMapCamera(lookingAtCenter: annotation.coordinate, fromEyeCoordinate: annotation.coordinate, eyeAltitude: 2500)
        
        mapView.setCamera(camera, animated: animated)
        mapView.selectAnnotation(annotation, animated: animated)
    }
  }
}
