//
//  TKRealTime.swift
//  TripKit
//
//  Created by Adrian Schönig on 25.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public enum TKRealTimeUpdateProgress<E> {
  case idle
  case updating
  case updated(E)
}

/// :nodoc:
public protocol TKRealTimeUpdatable {
  
  /// Whether the particular objects should be updated at all
  var wantsRealTimeUpdates: Bool { get }
}

extension TKRealTimeUpdatable {
  
  func wantsRealTimeUpdates(forStart start: Date, end: Date, forPreplanning: Bool) -> Bool {
    if forPreplanning {
      return start.timeIntervalSinceNow < 12 * 60 * 60 // half a day in advance
          && end.timeIntervalSinceNow > -60 * 60 // an hour ago
    } else {
      return start.timeIntervalSinceNow < 45 * 60 // start isn't more than 45 minutes from now
          && end.timeIntervalSinceNow > -30 * 60 // end isn't more than 30 minutes ago
    }
  }
  
}
