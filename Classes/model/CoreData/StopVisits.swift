//
//  StopVisits.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension StopVisits {
  
  public func grouping(previous: StopVisits?, next: StopVisits?) -> SGKGrouping {
    let sameAsBefore = previous?.searchString == searchString
    let sameAsAfter = next?.searchString == searchString
    
    switch (sameAsBefore, sameAsAfter) {
    case (true, true): return .middle
    case (true, _):    return .end
    case (_, true):    return .start
    default:           return .individual
    }
  }
  
}
