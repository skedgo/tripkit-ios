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
  
  public static func streamRealTime(for trip: Trip, pause: Observable<Bool>) -> Observable<TKRealTimeUpdateProgress<Trip>> {
    guard trip.wantsRealTimeUpdates else { return .empty() }
    
    // LATER: It might be better to only advance the counter once the inner observable has finished. Currently it's up to the builder to not hit the server too frequently.
    
    let counterAdvanced = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
    
    return Observable.combineLatest(counterAdvanced, pause.startWith(false)) { (counter: $0, pause: $1) }
      .filter { TKUITripModeByModeCard.config.builder.shouldUpdate(trip: trip, counter: $0.counter) && !$0.pause }
      .flatMapLatest { _ -> Observable<TKRealTimeUpdateProgress<Trip>> in
        let previousURLString = trip.updateURLString
        return TKRealTimeFetcher.rx.update(trip)
          .map { ($1 && $0.updateURLString == previousURLString) ? .idle : .updated($0) }
          .asObservable()
          .startWith(.updating)
      }
      .startWith(.idle)
  }
  
}
