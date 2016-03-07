//
//  RGAgendaFaker.swift
//  RioGo
//
//  Created by Adrian Schoenig on 25/02/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import CoreLocation
import RxSwift

struct TKAgendaFaker: TKAgendaBuilderType {
  func buildTrack(forItems items: [TKAgendaInputItem], startDate: NSDate, endDate: NSDate, privateVehicles: [STKVehicular], tripPatterns: [ [String: AnyObject] ]) -> Observable<[TKAgendaOutputItem]> {
    if items.count <= 1 {
      return Observable.just(items.flatMap { $0.asFakeOutput() } )
    }
    
    return Observable.create { subscriber in
      let scheduler = SerialDispatchQueueScheduler(internalSerialQueueName: "Timer")
      let subscription = Observable<Int>.timer(0, period: 1, scheduler: scheduler)
        .observeOn(MainScheduler.instance)
        .subscribeNext {
          let events = TKAgendaFaker.inputsReturningHome(items)
          if $0 < 1 {
            subscriber.onNext(TKAgendaFaker.trackWithTrips(events, usePlaceholders: true))
          } else {
            subscriber.onNext(TKAgendaFaker.trackWithTrips(events, usePlaceholders: false))
            subscriber.onCompleted()
          }
      }
      return AnonymousDisposable {
        subscription.dispose()
      }
    }
  }
  
  private static func inputsReturningHome(items: [TKAgendaInputItem]) -> [TKAgendaInputItem] {
    if let first = items.first,
       let last = items.last,
       case let .Event(startEvent) = first,
       case let .Event(lastEvent) = last
       where startEvent.kind == .Stay && lastEvent.kind != .Stay {
      return items + [first]
    } else {
      return items
    }
  }
  
  private static func trackWithTrips(items: [TKAgendaInputItem], usePlaceholders: Bool) -> [TKAgendaOutputItem] {
    let (outputs, _) = items.reduce( ([] as [TKAgendaOutputItem], nil as TKAgendaInputItem?) ) { previous, nextInput in
      // Unexpected state
      guard let next = nextInput.asFakeOutput() else { fatalError("unexpected Input: \(nextInput)") }
      
      // The very first
      guard let lastInput = previous.1 else { return ([next], nextInput) }

      let outputs = previous.0

      // Only need trips between events
      guard case let .Event(lastEvent) = lastInput,
            case let .Event(nextEvent) = nextInput else {
        return (outputs + [next], nextInput)
      }
      
      // Inserting trips in between events
      let tripStart = lastEvent.endDate
      let tripEnd = nextEvent.startDate
      if tripStart == nil && tripEnd == nil {
        return (outputs + [next], nextInput)
      } else if usePlaceholders {
        let placeholder = TKAgendaOutputItem.TripPlaceholder(tripStart, tripEnd)
        return (outputs + [placeholder, next], nextInput)
      } else {
        let trip = tripStart != nil
          ? FakeTrip(forDate: tripStart!, isArriveBefore: true)
          : FakeTrip(forDate: tripEnd!, isArriveBefore: false)
        let tripOutput = TKAgendaOutputItem.Trip(TKAgendaTripOutput(withTrip: trip, forInput: nil))
        return (outputs + [tripOutput, next], nextInput)
      }
    }
    
    return outputs
  }
}

extension TKAgendaInputItem {
  func asFakeOutput() -> TKAgendaOutputItem? {
    switch self {
    case .Event(let input):
      return .Event(TKAgendaEventOutput(forInput: input, effectiveStart: input.startDate, effectiveEnd: input.endDate, isContinuation: false))
    case .Trip(let input) where input.trip != nil:
      return .Trip(TKAgendaTripOutput(withTrip: input.trip!, forInput: input))
    default:
        return nil
    }
  }
}


private class FakeTrip: NSObject, STKTrip {
  @objc let costValues = [NSNumber(integer: STKTripCostType.Duration.rawValue): "30 Minutes"]
  @objc let departureTimeZone = NSTimeZone.systemTimeZone()
  @objc let departureTimeIsFixed = true

  @objc let departureTime: NSDate
  @objc let arrivalTime: NSDate
  @objc let isArriveBefore: Bool
  
  init(forDate date: NSDate, isArriveBefore: Bool) {
    self.isArriveBefore = isArriveBefore
    if isArriveBefore {
      arrivalTime = date
      departureTime = date.dateByAddingTimeInterval(-30 * 60)
    } else {
      departureTime = date
      arrivalTime = date.dateByAddingTimeInterval(30 * 60)
    }
  }
  
  @objc
  func segmentsWithVisibility(visibility: STKTripSegmentVisibility) -> [STKTripSegment] {
    return [ FakeBusSegment() ]
  }
}

private class FakeBusSegment: NSObject, STKTripSegment {
  @objc let tripSegmentModeColor: UIColor? = nil
  @objc let tripSegmentModeImage: UIImage? = nil
  @objc let tripSegmentInstruction = "Bus"
  @objc let tripSegmentMainValue: AnyObject = NSDate()
  @objc let tripSegmentTimeZone = NSTimeZone.systemTimeZone()
}
