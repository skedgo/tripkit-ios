//
//  RouteMapManager.swift
//  Pods
//
//  Created by Adrian Schoenig on 12/1/17.
//
//

import Foundation
import MapKit

extension RouteMapManager {
  
  public func sort(_ overlays: [MKOverlay]) -> [MKOverlay] {
    
    return overlays.sorted { one, two -> Bool in
      
      guard
        let travelledOne = (one as? STKRoutePolyline)?.route.routeIsTravelled?(),
        let travelledTwo = (two as? STKRoutePolyline)?.route.routeIsTravelled?()
        else { return true }
      
      if !travelledOne && travelledTwo {
        return true // one before two
      } else {
        return false // one after two
      }
      
    }
    
  }
  
}
