//
//  TripRequest.swift
//  Pods
//
//  Created by Adrian Schoenig on 18/11/16.
//
//

import Foundation

extension TripRequest {
 
  public func determineRegions() -> [SVKRegion] {
    let start = self.fromLocation.coordinate
    let end = self.toLocation.coordinate
    return SVKRegionManager.sharedInstance().localRegions(start: start, end: end)
  }
  
}
