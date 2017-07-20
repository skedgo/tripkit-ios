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



public enum TKTTPifierInputItem {
  case event(TKTTPifierEventInputType)
  
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
    }
    
    precondition(!timesAreFixed || startTime != nil, "You need a start, when times are fixed")
    return timesAreFixed

  }
  
  var startTime: Date? {
    switch self {
    case .event(let eventInput):
      return eventInput.startDate
    }
  }
  
  var endTime: Date? {
    switch self {
    case .event(let eventInput):
      return eventInput.endDate
    }
  }
  
  var start: CLLocationCoordinate2D {
    switch self {
    case .event(let eventInput):
      return eventInput.coordinate
    }
  }
  
  func needsTrip(to other: TKTTPifierInputItem) -> Bool {
    switch self {
    case .event(let eventInput):
      return true
    }
  }
}

@objc
public protocol TKTTPifierEventInputType {
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

extension TKTTPifierEventInputType {
  public func equalsForAgenda(_ other: TKTTPifierEventInputType) -> Bool {
    // We only care about the ID and user-modifiable fields
    return startDate == other.startDate
      && endDate == other.endDate
      && identifier == other.identifier
      && fixedOrder?.intValue == other.fixedOrder?.intValue
  }
}


public enum TKTTPifierOutputItem {
  case event(TKTTPifierEventOutput)
  case stayPlaceholder

  case tripOptions([TKTTPifierTripOptionType])
  
  /**
   Placeholder for where a trip will likely be. First date is predicted start date, second date is predicted end date.
   */
  case tripPlaceholder(Date?, Date?, String)
}

public class TKTTPifierEventOutput: NSObject {
  public let input: TKTTPifierEventInputType
  
  public init(forInput input: TKTTPifierEventInputType) {
    self.input = input
  }
}

extension TKTTPifierEventOutput {
  func equalsForAgenda(_ other: TKTTPifierEventOutput) -> Bool {
    return input.equalsForAgenda(other.input)
  }
}



public typealias ModeIdentifier = String
public typealias DistanceUnit = Float
public typealias PriceUnit = Float

public struct TKTTPifierValue<Element: ValueType> : Unmarshaling {
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

extension TKTTPifierValue {
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

public protocol TKTTPifierTripOptionSegmentType: STKTripSegmentDisplayable, STKDisplayableRoute {
}

public protocol TKTTPifierTripOptionType {
  var segments: [TKTTPifierTripOptionSegmentType] { get }
  var usedModes: [ModeIdentifier] { get }
  var duration: TKTTPifierValue<TimeInterval> { get }
  var score: TKTTPifierValue<Double> { get }

  var price: TKTTPifierValue<PriceUnit>? { get }
  var distance: DistanceUnit? { get }
  
  var earliestDeparture: TimeInterval? { get }
  var latestDeparture: TimeInterval? { get }
}

extension TKTTPifierTripOptionType {
  var price: TKTTPifierValue<PriceUnit>? { return nil }
  var distance: DistanceUnit? { return nil }
  
  var earliestDeparture: TimeInterval? { return nil }
  var latestDeparture: TimeInterval? { return nil }
  
  var segments: [TKTTPifierTripOptionSegmentType] {
    return usedModes.map { mode -> TKMinimalSegment in
      let image = SVKTransportModes.image(forModeIdentifier: mode)
      return TKMinimalSegment(modeImage: image)
    }
  }
}

private class TKMinimalSegment: NSObject, TKTTPifierTripOptionSegmentType {
  
  init(modeImage image: SGKImage?) {
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
  let tripSegmentModeImage: SGKImage?
  
  // MARK: STKDisplayableRoute
  
  var routePath: [Any] = []
  var routeIsTravelled: Bool = true
  var routeDashPattern: [NSNumber]? = nil
  var showRoute: Bool = true
  var routeColor: SGKColor? = nil
  
}

