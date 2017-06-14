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
  static func fakeInsert(_ locations: [TKTTPifierInputItem], into: [TKTTPifierInputItem]) -> Observable<[TKTTPifierOutputItem]> {

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
        .subscribe(onNext: {
          let events = TKTTPifierFaker.inputsReturningHome(inserted)
          if $0 < 1 {
            subscriber.onNext(TKTTPifierFaker.trackWithTrips(events, usePlaceholders: true))
          } else {
            subscriber.onNext(TKTTPifierFaker.trackWithTrips(events, usePlaceholders: false))
            subscriber.onCompleted()
          }
        })
      return Disposables.create {
        subscription.dispose()
      }
    }
  }
  
  fileprivate static func inputsReturningHome(_ items: [TKTTPifierInputItem]) -> [TKTTPifierInputItem] {
    if let first = items.first {
      return items + [first]
    } else {
      return items
    }
  }
  
  fileprivate static func trackWithTrips(_ items: [TKTTPifierInputItem], usePlaceholders: Bool, placeholderTitle: String? = nil) -> [TKTTPifierOutputItem] {
    let (outputs, _) = items.reduce( ([] as [TKTTPifierOutputItem], nil as TKTTPifierInputItem?) ) { previous, nextInput in

      guard let next = nextInput.asFakeOutput() else { fatalError("unexpected Input: \(nextInput)") }

      let (outputs, previousInput) = previous

      // The very first
      guard previousInput != nil else { return ([next], nextInput) }
      
      // Inserting trips in between events
      let title = placeholderTitle ?? NSLocalizedString("Calculating trips...", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Placeholder title while calculating trips")
      let outputItem = usePlaceholders
        ? TKTTPifierOutputItem.tripPlaceholder(nil, nil, title)
        : TKTTPifierOutputItem.tripOptions([FakeTripOption()])
      
      return (outputs + [outputItem, next], nextInput)
    }
    
    return outputs
  }
}

private struct FakeTripOption: TKTTPifierTripOptionType {
  let usedModes: [ModeIdentifier] = ["pt_pub", "wa_wal"]
  let duration = TKTTPifierValue<TimeInterval>(average: 30 * 60)
  let price = TKTTPifierValue(average: 1.5)
  let score = TKTTPifierValue(average: 3.0)
}

