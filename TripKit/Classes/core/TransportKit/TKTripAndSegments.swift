//
//  STKTripAndSegments.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

@objc
public enum TKTripCostType : Int, Codable {
  case score
  case time
  case duration
  case price
  case carbon
  case hassle
  case walking
  case calories
  case count
}

@objc
public enum TKTripSegmentVisibility : Int, Codable {
  
  /// never visible in UI
  case hidden
  
  case inDetails
  
  case onMap
  
  case inSummary
}

