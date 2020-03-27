//
//  TKCoreDataParserHelper.swift
//  TripKit-iOS
//
//  Created by Adrian Schönig on 25.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

/// :nodoc:
extension TKCoreDataParserHelper {
  
  @objc(configureVisit:fromShapeStopDict:timesRelativeToDate:)
  public static func configure(_ visit: StopVisits, fromShapeStopDict dict: [String: Any], timesRelativeTo relative: Date?) {
    
    precondition((visit.service as Service?) != nil)
    precondition((visit.index as NSNumber?) != nil)
    precondition(visit.index.intValue >= 0)
    
    // when we re-use an existing visit, we need to be conservative
    // as to not overwrite a previous arrival/departure with a new 'nil'
    // value. this can happen, say, with the 555 loop where 'circular quay'
    // is both the first and last stop. we don't want to overwrite the
    // initial departure with the nil value when the service gets back there
    // at the end of its loop.
    if let bearing = dict["bearing"] as? Int {
      visit.bearing = NSNumber(value: bearing)
    }
    
    // TODO: Handle new relative time (?)
    //   - should then pass in a time that these are relative to, i.e.,
    //     a departure time
    if let arrival = dict["arrival"] as? TimeInterval {
      visit.arrival = Date(timeIntervalSince1970: arrival)
    } else if let offset = dict["relativeArrival"] as? TimeInterval, let arrival = relative?.addingTimeInterval(offset) {
      visit.arrival = arrival
    }

    if let departure = dict["departure"] as? TimeInterval {
      visit.departure = Date(timeIntervalSince1970: departure)
    } else if let offset = dict["relativeDeparture"] as? TimeInterval, let departure = relative?.addingTimeInterval(offset) {
      visit.departure = departure
    }

    guard visit.arrival != nil || visit.departure != nil else {
      return
    }
    
    visit.triggerRealTimeKVO()
      
    // keep original time before we touch it with real-time data
    visit.originalTime = visit.departure ?? visit.arrival

    // frequency-based entries don't have times, so they don't have a region-day either
    visit.adjustRegionDay()
  }

  private static func absoluteTime(offset: TimeInterval?, onRelativeTime relative: Date?) -> Date? {
    guard let offset = offset, let relative = relative else { return nil }
    return relative.addingTimeInterval(offset)
  }
}

extension Shape {
  
  /// :nodoc:
  @objc
  public func _setInstruction(_ raw: String) {
    switch raw {
    case "HEAD_TOWARDS":        self.instruction = .headTowards
    case "CONTINUE_STRAIGHT":   self.instruction = .continueStraight
    case "TURN_SLIGHTLY_LEFT":  self.instruction = .turnSlightyLeft
    case "TURN_LEFT":           self.instruction = .turnLeft
    case "TURN_SHARPLY_LEFT":   self.instruction = .turnSharplyLeft
    case "TURN_SLIGHTLY_RIGHT": self.instruction = .turnSlightlyRight
    case "TURN_RIGHT":          self.instruction = .turnRight
    case "TURN_SHARPLY_RIGHT":  self.instruction = .turnSharplyRight
    default:                    self.instruction = nil
    }
  }
  
}
