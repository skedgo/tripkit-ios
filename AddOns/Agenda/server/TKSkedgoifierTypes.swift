//
//  TKSkedgoifierTypes.swift
//  TripKit
//
//  Created by Adrian Schoenig on 14/06/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

@objc
public enum TKSkedgoifierEventKind: Int {
  case currentLocation
  case activity
  case routine
  case stay
  case home
}

@objc
public protocol TKSkedgoifierEventInputType: TKAgendaEventInputType {
  var timeZone: TimeZone { get }
  
  var title: String { get }
  
  var kind: TKSkedgoifierEventKind { get }
  
  /**
   - returns: Whether this event should be considered when calculating routes for the day. You might want to exclude events that are cancelled or that the user declined. Suggested default: true.
   */
  var includeInRoutes: Bool { get }
  
  /**
   - returns: Indicator that the user wants to get to this event directly without returning to a lower-priority event before. Suggested default: false.
   */
  var goHereDirectly: Bool { get }
}

public class TKSkedgoifierEventOutput: TKAgendaEventOutput {
  let effectiveStart: Date?
  let effectiveEnd: Date?
  let isContinuation: Bool

  public init(forInput input: TKAgendaEventInputType, effectiveStart: Date?, effectiveEnd: Date?, isContinuation: Bool) {
    self.effectiveStart = effectiveStart
    self.effectiveEnd = effectiveEnd
    self.isContinuation = isContinuation

    super.init(forInput: input)
  }

}
