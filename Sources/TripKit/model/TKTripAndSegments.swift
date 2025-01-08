//
//  STKTripAndSegments.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

@objc
public enum TKTripSegmentVisibility : Int, Codable {
  
  /// never visible in UI
  case hidden
  
  case inDetails
  
  case onMap
  
  case inSummary
}

