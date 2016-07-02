//
//  TKTTPifierFaker.swift
//  RioGo
//
//  Created by Adrian Schoenig on 14/06/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import CoreLocation
import RxSwift

enum TKTTPifierFaker {
  static func fakeInsert(locations: [TKAgendaInputItem], into: [TKAgendaInputItem]) -> Observable<[TKAgendaOutputItem]> {

    // Add all at end
    var inserted = into
    inserted.appendContentsOf(locations)
    
    if inserted.count <= 1 {
      return Observable.just(inserted.flatMap { $0.asFakeOutput() } )
    }
    
    return Observable.create { subscriber in
      let scheduler = SerialDispatchQueueScheduler(internalSerialQueueName: "Timer")
      let subscription = Observable<Int>.timer(0, period: 1, scheduler: scheduler)
        .observeOn(MainScheduler.instance)
        .subscribeNext {
          let events = TKTTPifierFaker.inputsReturningHome(inserted)
          if $0 < 1 {
            subscriber.onNext(TKTTPifierFaker.trackWithTrips(events, usePlaceholders: true))
          } else {
            subscriber.onNext(TKTTPifierFaker.trackWithTrips(events, usePlaceholders: false))
            subscriber.onCompleted()
          }
      }
      return AnonymousDisposable {
        subscription.dispose()
      }
    }
  }
  
  private static func inputsReturningHome(items: [TKAgendaInputItem]) -> [TKAgendaInputItem] {
    if let first = items.first {
      return items + [first]
    } else {
      return items
    }
  }
  
  private static func trackWithTrips(items: [TKAgendaInputItem], usePlaceholders: Bool) -> [TKAgendaOutputItem] {
    let (outputs, _) = items.reduce( ([] as [TKAgendaOutputItem], nil as TKAgendaInputItem?) ) { previous, nextInput in

      guard let next = nextInput.asFakeOutput() else { fatalError("unexpected Input: \(nextInput)") }

      let (outputs, previousInput) = previous

      // The very first
      guard previousInput != nil else { return ([next], nextInput) }
      
      // Inserting trips in between events
      let outputItem = usePlaceholders
        ? TKAgendaOutputItem.TripPlaceholder(nil, nil)
        : TKAgendaOutputItem.TripOptions([FakeTripOption()])
      
      return (outputs + [outputItem, next], nextInput)
    }
    
    return outputs
  }
}

private struct FakeTripOption: TKAgendaTripOptionType {
  let usedModes: [ModeIdentifier] = ["pt_pub", "wa_wal"]
  let duration: NSTimeInterval = 30 * 60
  let distance: DistanceUnit = 1_000
  let price: PriceUnit = 1.5
  let score: Float = 3
}

