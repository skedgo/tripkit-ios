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
  }
  
  let realTimeUpdate: Driver<TKRealTimeUpdateProgress<Trip>>
  
  private static func fetchRealTime(for trip: Trip) -> Driver<TKRealTimeUpdateProgress<Trip>> {
    guard trip.wantsRealTimeUpdates else { return .empty() }
    
    return Observable<Int>.interval(30, scheduler: MainScheduler.instance)
      .flatMapLatest { _ in
        TKBuzzRealTime.rx.update(trip)
          .map { $1 ? .idle : .updated($0) }
          .asObservable()
          .startWith(.updating)
      }
      .startWith(.idle)
      .asDriver(onErrorDriveWith: .empty())
  }
  
}
