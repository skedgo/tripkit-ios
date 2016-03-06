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
  func buildTrack(items: [TKAgendaInputItem]) -> Observable<[TKAgendaOutputItem]> {
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
      guard let next = nextInput.asFakeOutput() else { return previous }
      
      let outputs = previous.0
      
      if let lastInput = previous.1 {
        if case let .Event(lastEvent) = lastInput,
           case let .Event(nextEvent) = nextInput {
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
            let tripOutput = TKAgendaOutputItem.Trip(TKAgendaTripOutput(input: nil, trip: trip, fromIdentifier: nil, toIdentifier: nil))
            return (outputs + [tripOutput, next], nextInput)
          }
        } else {
          return (outputs + [next], nextInput)
        }
      } else {
        return ([next], nextInput)
      }
    }
    return outputs
  }
}

extension TKAgendaInputItem {
  func asFakeOutput() -> TKAgendaOutputItem? {
    switch self {
    case .Event(let input):
      return .Event(TKAgendaEventOutput(input: input, effectiveStart: input.startDate, effectiveEnd: input.endDate, isContinuation: false))
    case .Trip:
      return nil // TODO
    }
  }
}


private class FakeTrip: NSObject, STKTrip {
  @objc let costValues = [NSNumber(unsignedInt: STKTripCostTypeDuration.rawValue): "30 Minutes"]
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
