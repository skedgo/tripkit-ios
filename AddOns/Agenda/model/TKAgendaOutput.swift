//
//  TKAgendaOutput.swift
//  TripGo
//
//  Created by Adrian Schoenig on 3/03/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

@objc
class TKAgendaEventOutputItem: NSObject, TKAgendaEventOutputType {
  
  let input: TKAgendaEventInputType
  let effectiveStart: NSDate
  let effectiveEnd: NSDate?
  let isContinuation: Bool
  
  init(forInput input: TKAgendaEventInputType, effectiveStart: NSDate, effectiveEnd: NSDate, isContinuation: Bool) {
    self.input = input
    self.effectiveStart = effectiveStart
    self.effectiveEnd = effectiveEnd
    self.isContinuation = isContinuation
  }
  
}

@objc
class TKAgendaTripOutputItem: NSObject, TKAgendaTripOutputType {
  let input: TKAgendaTripInputType?
  let trip: Trip
  
  var fromIdentifier: String?
  var toIdentifier: String?
  
  init(trip: Trip, forInput input: TKAgendaTripInputType?) {
    self.input = input
    self.trip = trip
  }
}