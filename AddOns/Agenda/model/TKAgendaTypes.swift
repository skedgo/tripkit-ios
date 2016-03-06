//
//  TKAgendaInputType.swift
//  TripGo
//
//  Created by Adrian Schoenig on 3/03/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import CoreLocation
import RxSwift

public protocol TKAgendaType {
  var startDate: NSDate { get }
  var endDate: NSDate { get }
  var items: Observable<[TKAgendaOutputItem]> { get }
}

public enum TKAgendaInputItem {
  case Event(TKAgendaEventInputType)
  case Trip(TKAgendaTripInputType)
}

public protocol TKAgendaInputType {
  var startDate: NSDate? { get }
  var endDate: NSDate? { get }
  var timeZone: NSTimeZone { get }
}

public enum TKAgendaEventKind {
  case CurrentLocation
  case Activity
  case Routine
  case Stay
  case Home
}

public protocol TKAgendaEventInputType {
  var startDate: NSDate? { get }
  var endDate: NSDate? { get }
  
  /**
   The coordinate where this input takes place. The agenda will try to route here. Invalid coordinates will be ignored.
   */
  var coordinate: CLLocationCoordinate2D { get }
  
  var identifier: String? { get }
  
  var title: String { get }
  
  var kind: TKAgendaEventKind { get }
  
  /**
   - returns: Whether this event should be considered when calculating routes for the day. You might want to exclude events that are cancelled or that the user declined. Suggested default: true.
  */
  var includeInRoutes: Bool { get }
  
  /**
   - returns: Indicator that the user wants to get to this event directly without returning to a lower-priority event before. Suggested default: false.
  */
  var goHereDirectly: Bool { get }
  
  /**
   - returns: The source model for this item. This won't be used by in any agenda calculations, but this is helpful for you to associate something with your input. Suggested default: nil.
   */
  var sourceModel: Any? { get }
}

extension TKAgendaInputItem {
  func needsTrip(to other: TKAgendaInputItem) -> Bool {
    if case .Trip = self,
       case .Trip = other {
      return false
    } else {
      return true
    }
  }
}


public protocol TKAgendaTripInputType: TKAgendaInputType {
  var departureTime: NSDate { get }
  var arrivalTime: NSDate { get }
  
  var origin: CLLocationCoordinate2D { get }
  var destination: CLLocationCoordinate2D { get }
  
  /**
   - returns: The trip this trip input item is for. If this is `nil`, make sure to return soemthing from `modes`.
   */
  var trip: Trip? { get }
  
  /**
   - returns: The used modes of this trip. Only needs to return something if `trip` returns nil`.
   */
  var modes: [String]? { get }
}

public enum TKAgendaOutputItem {
  case Event(TKAgendaEventOutput)
  case Trip(TKAgendaTripOutput)
  case TripPlaceholder(NSDate?, NSDate?)
}

public struct TKAgendaEventOutput {
  let input: TKAgendaEventInputType
  let effectiveStart: NSDate?
  let effectiveEnd: NSDate?
  let isContinuation: Bool
}

public struct TKAgendaTripOutput {
  let input: TKAgendaTripInputType?
  let trip: STKTrip
  let fromIdentifier: String?
  let toIdentifier: String?
}

