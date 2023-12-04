//
//  TKRealTimeHelper.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 2/7/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKit

import RxSwift

public enum TKRealTimeHelper {
  
  public static func streamRealTime(for trip: Trip, pause: Observable<Bool>) -> Observable<Trip> {
    guard trip.wantsRealTimeUpdates else { return .empty() }
    
    // LATER: It might be better to only advance the counter once the inner observable has finished. Currently it's up to the builder to not hit the server too frequently.
    
    let counterAdvanced = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
    
    return Observable.combineLatest(counterAdvanced, pause.startWith(false)) { (counter: $0, pause: $1) }
      .filter {
        TKUITripModeByModeCard.config.builder.shouldUpdate(trip: trip, counter: $0.counter) && !$0.pause
      }
      .flatMapLatest { _ -> Observable<(Trip, String?)> in
        // `trip` will generally stay the same as it's updated in-place, but we
        // pass back the update URL as that will change between updates if
        // the trip itself changed.
        return TKRealTimeFetcher.rx.update(trip)
          .observe(on: MainScheduler.instance)
          .map { trip, _ in (trip, trip.updateURLString) }
          .asObservable()
          .catchAndReturn((trip, trip.updateURLString))
      }
      .distinctUntilChanged {
        // We compare the update URLs between each time we fire rather than
        // just using the `didUpdate`. This is to catch cases where the trip
        // was updated in the mean time by some other method (e.g., bookings)
        // but whoever is consuming this stream wouldn't be aware of that, but
        // still wants to be informed if the trip has changed since the last
        // time this fired. (EVEN IF the `rx.update` didn't actually update
        // the trip as the object was already updated!)
        return $0.1 != nil && $0.1 == $1.1
      }
      .map(\.0)
  }
  
}
