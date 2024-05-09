//
//  TKUILocationMapManager.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 1/5/2023.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import MapKit

import TripKit

/// A simple map manager that displays the pin of the provided ``TKNamedCoordinate``
public class TKUILocationMapManager: TKUIMapManager {
  
  let coordinate: TKNamedCoordinate
  
  public init(for namedCoordinate: TKNamedCoordinate) {
    self.coordinate = namedCoordinate
    
    super.init()
    
    self.preferredZoomLevel = .road
    
    self.annotations = [coordinate]
  }
  
  public override func takeCharge(of mapView: MKMapView, animated: Bool) {
    super.takeCharge(of: mapView, animated: animated)
    
    self.zoom(to: [coordinate], animated: animated)
  }
  
}
