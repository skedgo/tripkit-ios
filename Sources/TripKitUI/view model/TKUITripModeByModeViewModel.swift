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

import TripKit

@MainActor
class TKUITripModeByModeViewModel {
  
  init(trip: Trip) {
    self.trip = trip
    
    self.realTimeUpdate = TKUITripModeByModeViewModel
      .fetchRealTime(for: trip)
      .do(onNext: { trip in
        NotificationCenter.default.post(name: .TKUIUpdatedRealTimeData, object: trip)
        
        // Segment changed, too
        trip.segments
          .map { Notification(name: .TKUIUpdatedRealTimeData, object: $0) }
          .forEach(NotificationCenter.default.post)
      })
      .map { trip in
        .updated(trip)
      }
      .startWith(.idle)
  }
  
  let trip: Trip
  
  let realTimeUpdate: Driver<TKRealTimeUpdateProgress<Trip>>
  
  private static func fetchRealTime(for trip: Trip) -> Driver<Trip> {
    return TKRealTimeHelper.streamRealTime(for: trip, pause: .just(false))
      .asDriver(onErrorDriveWith: .empty())
  }
  
}
