//
//  TKFlexAgendaFaker.swift
//  RioGo
//
//  Created by Adrian Schoenig on 14/06/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import CoreLocation
import RxSwift

enum TKFlexAgendaFaker {
  static func fakeInsert(locations: Set<TKFlexAgendaVisit>, into: [TKFlexAgendaVisit]) -> Observable<[TKFlexAgendaOutputItem]> {

    // Add all at end (TODO: Shuffle?)
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
          let events = TKFlexAgendaFaker.inputsReturningHome(inserted)
          if $0 < 1 {
            subscriber.onNext(TKFlexAgendaFaker.trackWithTrips(events, usePlaceholders: true))
          } else {
            subscriber.onNext(TKFlexAgendaFaker.trackWithTrips(events, usePlaceholders: false))
            subscriber.onCompleted()
          }
      }
      return AnonymousDisposable {
        subscription.dispose()
      }
    }
  }
  
  private static func inputsReturningHome(items: [TKFlexAgendaVisit]) -> [TKFlexAgendaVisit] {
    if let first = items.first {
      return items + [first]
    } else {
      return items
    }
  }
  
  private static func trackWithTrips(items: [TKFlexAgendaVisit], usePlaceholders: Bool) -> [TKFlexAgendaOutputItem] {
    let (outputs, _) = items.reduce( ([] as [TKFlexAgendaOutputItem], nil as TKFlexAgendaVisit?) ) { previous, nextInput in

      let (outputs, previousInput) = previous
      let next = nextInput.asFakeOutput()
      
      // The very first
      guard previousInput != nil else { return ([next], nextInput) }
      
      // Inserting trips in between events
      let outputItem = usePlaceholders
        ? TKFlexAgendaOutputItem.TripPlaceholder
        : TKFlexAgendaOutputItem.TripOptions([FakeTripOption()])
      
      return (outputs + [outputItem, next], nextInput)
    }
    
    return outputs
  }
}

extension TKFlexAgendaVisit {
  func asFakeOutput() -> TKFlexAgendaOutputItem {
    return .Visit(self)
  }
}

private struct FakeTripOption: TKFlexAgendaTripOption {
  var modes: [ModeIdentifier] = ["pt_pub", "wa_wal"]
  var duration: NSTimeInterval = 30 * 60
  var distance: DistanceUnit = 1_000
  var price: PriceUnit = 1.5
}

