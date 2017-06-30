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
import Marshal



/**
 An Agenda encapsulates a user's plan for a time range.
 
 It is typically creating from user-specified input and then combined with smarts about travelling between events and suggesting order in which to do things; this plan is encapsulated in the `items` sequence.
 */
public protocol TKAgendaType {
  var startDate: Date { get }
  var endDate: Date { get }
  var triggerRebuild: Variable<Bool> { get }
  var inputItems: Observable<[TKAgendaInputItem]> { get }
  var outputItems: Observable<[TKAgendaOutputItem]?> { get }
  var lastError: Observable<Error?> { get }
}

public enum TKAgendaInputItem {
  case event(TKAgendaEventInputType)
  case trip(TKAgendaTripInputType)
  
  var isStay: Bool {
    if case let .event(eventInput) = self {
      return eventInput.isStay
    } else {
      return false
    }
  }
  
  var fixedOrder: Int? {
    if case let .event(eventInput) = self,
       let number = eventInput.fixedOrder {
      return number.intValue
    } else {
      return nil
    }
  }

  var timesAreFixed: Bool {
    let timesAreFixed: Bool
    
    switch self {
    case .event(let eventInput):
      timesAreFixed = eventInput.timesAreFixed
    case .trip:
      timesAreFixed = true
    }
    
    precondition(!timesAreFixed || startTime != nil, "You need a start, when times are fixed")
    return timesAreFixed

  }
  
  var startTime: Date? {
    switch self {
    case .event(let eventInput):
      return eventInput.startDate
    case .trip(let trip):
      return trip.departureTime
    }
  }
  
  var endTime: Date? {
    switch self {
    case .event(let eventInput):
      return eventInput.endDate
    case .trip(let trip):
      return trip.arrivalTime
    }
  }
  
  var start: CLLocationCoordinate2D {
    switch self {
    case .event(let eventInput):
      return eventInput.coordinate
    case .trip(let tripInput):
      return tripInput.origin
    }
  }
  
  func needsTrip(to other: TKAgendaInputItem) -> Bool {
    if case .trip = self,
      case .trip = other {
      return false
    } else {
      return true
    }
  }
}

@objc
public protocol TKAgendaEventInputType {
  var startDate: Date? { get }
  var endDate: Date? { get }

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

extension TKAgendaEventInputType {
  public func equalsForAgenda(_ other: TKAgendaEventInputType) -> Bool {
    // We only care about the ID and user-modifiable fields
    return startDate == other.startDate
      && endDate == other.endDate
      && identifier == other.identifier
      && fixedOrder?.intValue == other.fixedOrder?.intValue
  }
}


@objc
public protocol TKAgendaTripInputType: NSObjectProtocol {
  var departureTime: Date { get }
  var arrivalTime: Date { get }
  
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
  case event(TKAgendaEventOutput)
  case stayPlaceholder

  case trip(TKAgendaTripOutput)
  case tripOptions([TKAgendaTripOptionType])
  
  /**
   Placeholder for where a trip will likely be. First date is predicted start date, second date is predicted end date.
   */
  case tripPlaceholder(Date?, Date?, String)
}

public class TKAgendaEventOutput: NSObject {
  public let input: TKAgendaEventInputType
  
  public init(forInput input: TKAgendaEventInputType) {
    self.input = input
  }
}

extension TKAgendaEventOutput {
  func equalsForAgenda(_ other: TKAgendaEventOutput) -> Bool {
    return input.equalsForAgenda(other.input)
  }
}



public typealias ModeIdentifier = String
public typealias DistanceUnit = Float
public typealias PriceUnit = Float

public class TKAgendaTripOutput: NSObject {
  public let input: TKAgendaTripInputType?
  public let trip: STKTrip
  public var fromIdentifier: String?
  public var toIdentifier: String?
  
  public init(withTrip trip: STKTrip, forInput input: TKAgendaTripInputType?) {
    self.trip = trip
    self.input = input
  }
}

public struct TKAgendaValue<Element: ValueType> : Unmarshaling {
  public let average: Element
  public let min: Element?
  public let max: Element?
  public let unit: String?
  
  init(average: Element, min: Element? = nil, max: Element? = nil, unit: String? = nil) {
    self.average = average
    self.min = min
    self.max = max
    self.unit = unit
  }
  
  public init(object: MarshaledObject) throws {
    average = try  object.value(for: "average")
    min     = try? object.value(for: "min")
    max     = try? object.value(for: "max")
    unit    = try? object.value(for: "unit")
  }
  
}

extension TKAgendaValue {
  public var lower: Element {
    if let min = min {
      return min
    } else {
      return average
    }
  }

  public var upper: Element {
    if let max = max {
      return max
    } else {
      return average
    }
  }
}

public protocol TKAgendaTripOptionSegmentType: STKTripSegmentDisplayable, STKDisplayableRoute {
}

public protocol TKAgendaTripOptionType {
  var segments: [TKAgendaTripOptionSegmentType] { get }
  var usedModes: [ModeIdentifier] { get }
  var duration: TKAgendaValue<TimeInterval> { get }
  var score: TKAgendaValue<Double> { get }

  var price: TKAgendaValue<PriceUnit>? { get }
  var distance: DistanceUnit? { get }
  
  var earliestDeparture: TimeInterval? { get }
  var latestDeparture: TimeInterval? { get }
}

extension TKAgendaTripOptionType {
  var price: TKAgendaValue<PriceUnit>? { return nil }
  var distance: DistanceUnit? { return nil }
  
  var earliestDeparture: TimeInterval? { return nil }
  var latestDeparture: TimeInterval? { return nil }
  
  var segments: [TKAgendaTripOptionSegmentType] {
    return usedModes.map { mode -> TKMinimalSegment in
      let image = SVKTransportModes.image(forModeIdentifier: mode)
      return TKMinimalSegment(modeImage: image)
    }
  }
}

private class TKMinimalSegment: NSObject, TKAgendaTripOptionSegmentType {
  
  init(modeImage image: UIImage?) {
    tripSegmentModeImage = image
    
    super.init()
  }
  
  // MARK: STKTripSegmentDisplayable
  
  var tripSegmentModeColor: SGKColor? { return nil }
  var tripSegmentModeImageURL: URL? { return nil }
  var tripSegmentModeInfoIconType: STKInfoIconType { return .none }
  var tripSegmentModeTitle: String? { return nil }
  var tripSegmentModeSubtitle: String? { return nil }
  var tripSegmentFixedDepartureTime: Date? { return nil }
  var tripSegmentTimeZone: TimeZone? { return nil }
  var tripSegmentTimesAreRealTime: Bool { return false }
  var tripSegmentIsWheelchairAccessible: Bool { return false }
  let tripSegmentModeImage: UIImage?
  
  // MARK: STKDisplayableRoute
  
  fileprivate func routePath() -> [Any] {
    return []
  }
  
  fileprivate func routeColour() -> UIColor? {
    return nil
  }
  
}

