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
  static func fakeInsert(_ locations: [TKAgendaInputItem], into: [TKAgendaInputItem]) -> Observable<[TKAgendaOutputItem]> {

    // Add all at end
    var inserted = into
    inserted.append(contentsOf: locations)
    
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
  
  private static func inputsReturningHome(_ items: [TKAgendaInputItem]) -> [TKAgendaInputItem] {
    if let first = items.first {
      return items + [first]
    } else {
      return items
    }
  }
  
  private static func trackWithTrips(_ items: [TKAgendaInputItem], usePlaceholders: Bool, placeholderTitle: String? = nil) -> [TKAgendaOutputItem] {
    let (outputs, _) = items.reduce( ([] as [TKAgendaOutputItem], nil as TKAgendaInputItem?) ) { previous, nextInput in

      guard let next = nextInput.asFakeOutput() else { fatalError("unexpected Input: \(nextInput)") }

      let (outputs, previousInput) = previous

      // The very first
      guard previousInput != nil else { return ([next], nextInput) }
      
      // Inserting trips in between events
      let title = placeholderTitle ?? NSLocalizedString("Calculating trips...", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Placeholder title while calculating trips")
      let outputItem = usePlaceholders
        ? TKAgendaOutputItem.tripPlaceholder(nil, nil, title)
        : TKAgendaOutputItem.tripOptions([FakeTripOption()])
      
      return (outputs + [outputItem, next], nextInput)
    }
    
    return outputs
  }
}

private struct FakeTripOption: TKAgendaTripOptionType {
  let usedModes: [ModeIdentifier] = ["pt_pub", "wa_wal"]
  let duration = TKAgendaValue<TimeInterval>(average: 30 * 60)
  let price = TKAgendaValue(average: 1.5)
  let score = TKAgendaValue(average: 3.0)
}

