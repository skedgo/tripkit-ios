//
//  DLSEntry.swift
//  TripKit
//
//  Created by Adrian Schönig on 25.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation


// MARK: - TKRealTimeUpdatable

extension DLSEntry {
  public override var wantsRealTimeUpdates: Bool {
    guard service.isRealTimeCapable,
      let departure = departure,
      let arrival = arrival else { return false }
    return wantsRealTimeUpdates(forStart: departure, end: arrival, forPreplanning: false)
  }
}
