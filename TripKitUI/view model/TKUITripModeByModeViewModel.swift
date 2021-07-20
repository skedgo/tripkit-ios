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

class TKUITripModeByModeViewModel {
  
  init(trip: Trip) {
    self.trip = trip
    
    self.realTimeUpdate = TKUITripModeByModeViewModel
      .fetchRealTime(for: trip)
      .do(onNext: { update in
        guard case .updated(let trip) = update else { return }
        NotificationCenter.default.post(name: .TKUIUpdatedRealTimeData, object: trip)
        
        // Segment changed, too
        trip.segments
          .map { Notification(name: .TKUIUpdatedRealTimeData, object: $0) }
          .forEach(NotificationCenter.default.post)
      })
  }
  
  let trip: Trip
  
  let realTimeUpdate: Driver<TKRealTimeUpdateProgress<Trip>>
  
  private static func fetchRealTime(for trip: Trip) -> Driver<TKRealTimeUpdateProgress<Trip>> {
    return TKRealTimeHelper.streamRealTime(for: trip, pause: .just(false))
      .asDriver(onErrorDriveWith: .empty())
  }
  
}
