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

import SGCoreKit

struct TKAgendaFaker: TKAgendaBuilderType {
  func buildTrack(forItems items: [TKAgendaInputItem], startDate: NSDate, endDate: NSDate) -> Observable<[TKAgendaOutputItem]> {
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
  
  static func outputPlaceholders(_ items: [TKAgendaInputItem], placeholderTitle title: String? = nil) -> [TKAgendaOutputItem] {
    let events = inputsReturningHome(items)
    return trackWithTrips(events, usePlaceholders: true, placeholderTitle: title)
  }
  
  private static func inputsReturningHome(_ items: [TKAgendaInputItem]) -> [TKAgendaInputItem] {
    if let first = items.first,
       let last = items.last
      where first.isStay && !last.isStay {
      return items + [first]
    } else {
      return items
    }
  }
  
  private static func trackWithTrips(_ items: [TKAgendaInputItem], usePlaceholders: Bool, placeholderTitle: String? = nil) -> [TKAgendaOutputItem] {
    let (outputs, _) = items.reduce( ([] as [TKAgendaOutputItem], nil as TKAgendaInputItem?) ) { previous, nextInput in
      // Unexpected state
      guard let next = nextInput.asFakeOutput() else { fatalError("unexpected Input: \(nextInput)") }
      
      // The very first
      guard let lastInput = previous.1 else { return ([next], nextInput) }

      let outputs = previous.0

      // Only need trips between events
      guard case let .event(lastEvent) = lastInput,
            case let .event(nextEvent) = nextInput else {
        return (outputs + [next], nextInput)
      }
      
      // Inserting trips in between events
      let tripStart = lastEvent.endDate
      let tripEnd = nextEvent.startDate
      if tripStart == nil && tripEnd == nil {
        return (outputs + [next], nextInput)
      } else if usePlaceholders {
        let title = placeholderTitle ?? NSLocalizedString("Calculating trips...", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Placeholder title while calculating trips")
        let placeholder = TKAgendaOutputItem.TripPlaceholder(tripStart, tripEnd, title)
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
    case .event(let input):
      return .event(TKAgendaEventOutput(forInput: input))
    case .trip(let input) where input.trip != nil:
      return .Trip(TKAgendaTripOutput(withTrip: input.trip!, forInput: input))
    default:
        return nil
    }
  }
}


private class FakeTrip: NSObject, STKTrip {
  @objc let costValues = [NSNumber(integer: STKTripCostType.Duration.rawValue): "30 Minutes"]
  @objc let departureTimeZone = NSTimeZone.current
  @objc let departureTimeIsFixed = true

  @objc let departureTime: Date
  @objc let arrivalTime: Date
  @objc let isArriveBefore: Bool
  
  init(forDate date: Date, isArriveBefore: Bool) {
    self.isArriveBefore = isArriveBefore
    if isArriveBefore {
      arrivalTime = date
      departureTime = date.addingTimeInterval(-30 * 60)
    } else {
      departureTime = date
      arrivalTime = date.addingTimeInterval(30 * 60)
    }
  }
  
  @objc
  func segmentsWithVisibility(_ visibility: STKTripSegmentVisibility) -> [STKTripSegment] {
    return [ FakeBusSegment() ]
  }
  
  @objc
  func mainSegment() -> STKTripSegment {
    return segmentsWithVisibility(.InSummary).first!
  }
}

private class FakeBusSegment: NSObject, STKTripSegment {
  @objc let tripSegmentModeImage: UIImage? = nil
  @objc let tripSegmentInstruction = "Bus"
  @objc let tripSegmentMainValue: AnyObject = Date()
}
