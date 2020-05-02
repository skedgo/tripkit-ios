//
//  TKUITripModeByModeViewModel.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 03.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

class TKUITripModeByModeViewModel {
  
  init(trip: Trip) {
    self.realTimeUpdate = TKUITripModeByModeViewModel.fetchRealTime(for: trip)
    
    self.tripDidUpdate = NotificationCenter.default.rx
      .notification(.TKUIUpdatedRealTimeData, object: trip)
      .compactMap { $0.object as? Trip }
      .asSignal(onErrorSignalWith: .empty())
  }
  
  let realTimeUpdate: Driver<TKRealTimeUpdateProgress<Trip>>
  
  let tripDidUpdate: Signal<Trip>
  
  private static func fetchRealTime(for trip: Trip) -> Driver<TKRealTimeUpdateProgress<Trip>> {
    guard trip.wantsRealTimeUpdates else { return .empty() }
    
    // LATER: It might be better to only advance the counter once the inner observable has finished. Currently it's up to the builder to not hit the server too frequently.
    
    return Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
      .filter {
        TKUITripModeByModeCard.config.builder.shouldUpdate(trip: trip, counter: $0)
      }
      .flatMapLatest { (interval) -> Observable<TKRealTimeUpdateProgress<Trip>> in
        let previousURLString = trip.updateURLString
        return TKBuzzRealTime.rx.update(trip)
          .map { ($1 && $0.updateURLString == previousURLString) ? .idle : .updated($0) }
          .asObservable()
          .startWith(.updating)
      }
      .startWith(.idle)
      .asDriver(onErrorDriveWith: .empty())
  }
  
}
