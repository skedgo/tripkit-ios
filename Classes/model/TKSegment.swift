//
//  TKSegment.swift
//  Pods
//
//  Created by Adrian Schoenig on 31/10/16.
//
//

import Foundation

extension TKSegment {
  
  /// Validates the segment, to make sure it's in a consistent state.
  /// If it's in an inconsistent state, many things can go wrong. You might
  /// want to add calls to this method to assertions and precondition checks.
  public func validate() -> Bool {
    // Segments need a trip
    guard let trip = trip else { return false }
    
    // A segment should be in its trip's segments
    guard let _ = trip.segments().index(of: self) else { return false }
    
    // Passed all checks
    return true
  }
  
  
  func determineRegions() -> [SVKRegion] {
    guard let start = self.start?.coordinate, let end = self.end?.coordinate else { return [] }
    
    return SVKRegionManager.sharedInstance().localRegions(start: start, end: end)
  }
}

