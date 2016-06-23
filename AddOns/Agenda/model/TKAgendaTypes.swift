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
import RxCocoa

/**
 An Agenda encapsulates a user's plan for a time range.
 
 It is typically creating from user-specified input and then combined with smarts about travelling between events and suggesting order in which to do things; this plan is encapsulated in the `items` sequence.
 */
public protocol TKAgendaType {
  var startDate: NSDate { get }
  var endDate: NSDate { get }
  var items: Observable<[TKAgendaOutputItem]> { get }
  var lastError: Observable<ErrorType?> { get }
}

public enum TKAgendaInputItem {
  case Event(TKAgendaEventInputType)
  case Trip(TKAgendaTripInputType)
  
  var isStay: Bool {
    if case let .Event(eventInput) = self {
      return eventInput.isStay
    } else {
      return false
    }
  }
  
  var fixedOrder: Int? {
    if case let .Event(eventInput) = self,
       let number = eventInput.fixedOrder {
      return number.integerValue
    } else {
      return nil
    }
  }

  var timesAreFixed: Bool {
    switch self {
    case .Event(let eventInput):
      return eventInput.timesAreFixed
    case .Trip:
      return true
    }
  }
  
  var start: CLLocationCoordinate2D {
    switch self {
    case .Event(let eventInput):
      return eventInput.coordinate
    case .Trip(let tripInput):
      return tripInput.origin
    }
  }
  
  func needsTrip(to other: TKAgendaInputItem) -> Bool {
    if case .Trip = self,
      case .Trip = other {
      return false
    } else {
      return true
    }
  }
}

@objc
public protocol TKAgendaEventInputType {
  var startDate: NSDate? { get }
  var endDate: NSDate? { get }

  /**
   The coordinate where this input takes place. The agenda will try to route here. Invalid coordinates will be ignored.
   */
  var coordinate: CLLocationCoordinate2D { get }
  
  var identifier: String? { get }
  
  var fixedOrder: NSNumber? { get }
  
  /**
   - returns: Whether start + end date are fixed (e.g., an event with a set time), or if the agenda can move them around arbitrarily (e.g., best time of day to go to a certain attraction).
   */
  var timesAreFixed: Bool { get }
  
  /**
   - returns: The source model for this item. This won't be used by in any agenda calculations, but this is helpful for you to associate something with your input. Suggested default: nil.
   */
  var sourceModel: AnyObject? { get }
  
  var isStay: Bool { get }
}

@objc
public protocol TKAgendaTripInputType: NSObjectProtocol {
  var departureTime: NSDate { get }
  var arrivalTime: NSDate { get }
  
  var origin: CLLocationCoordinate2D { get }
  var destination: CLLocationCoordinate2D { get }
  
  /**
   - returns: The trip this trip input item is for. If this is `nil`, make sure to return soemthing from `modes`.
   */
  var trip: STKTrip? { get }
  
  /**
   - returns: The used modes of this trip. Only needs to return something if `trip` returns nil`.
   */
  var modes: [String]? { get }
}

public enum TKAgendaOutputItem {
  case Event(TKAgendaEventOutput)
  case Trip(TKAgendaTripOutput)
  case TripOptions([TKAgendaTripOptionType])
  
  /**
   Placeholder for where a trip will likely be. First date is predicted start date, second date is predicted end date.
   */
  case TripPlaceholder(NSDate?, NSDate?)
}

public class TKAgendaEventOutput: NSObject {
  let input: TKAgendaEventInputType
  
  init(forInput input: TKAgendaEventInputType) {
    self.input = input
  }
}

public typealias ModeIdentifier = String
public typealias DistanceUnit = Float
public typealias PriceUnit = Float

public class TKAgendaTripOutput: NSObject {
  let input: TKAgendaTripInputType?
  let trip: STKTrip
  var fromIdentifier: String?
  var toIdentifier: String?
  
  init(withTrip trip: STKTrip, forInput input: TKAgendaTripInputType?) {
    self.trip = trip
    self.input = input
  }
}

public protocol TKAgendaTripOptionType {
  
  var modes: [ModeIdentifier] { get }
  var duration: NSTimeInterval { get }
  var score: Float { get }

  var distance: DistanceUnit? { get }
  var price: PriceUnit? { get }
  
  var earliestDeparture: NSTimeInterval? { get }
  var latestDeparture: NSTimeInterval? { get }
}

extension TKAgendaTripOptionType {
  var distance: DistanceUnit? { return nil }
  var price: PriceUnit? { return nil }
  
  var earliestDeparture: NSTimeInterval? { return nil }
  var latestDeparture: NSTimeInterval? { return nil }
}


