//
//  TKUITripModeByModeCard+ViewModel.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 01.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

extension Notification.Name {
  static let TKUISegmentUpdatedWithRealTimeData = Notification.Name("TKUISegmentUpdatedWithRealTimeData")
}

extension TKUITripModeByModeCard {
  
  static func realTimeUpdate(for trip: Trip) -> Driver<TKRealTimeUpdateProgress> {
    guard trip.wantsRealTimeUpdates else { return .empty() }
    
    return Observable<Int>.interval(30, scheduler: MainScheduler.instance)
      .flatMapLatest { _ in
        TKBuzzRouter.rx.update(trip)
          .map { _ in .updated }
          .asObservable()
          .startWith(.updating)
      }
      .startWith(.idle)
      .asDriver(onErrorDriveWith: .empty())
  }
  
  static func notifyOfUpdates(in trip: Trip) {
    let segments = trip.segments
      
    segments.map { Notification(name: .TKUISegmentUpdatedWithRealTimeData, object: $0) }
      .forEach(NotificationCenter.default.post)
    
    segments.map { Notification(name: .TKUISemaphoreRequiresUpdate, object: $0) }
      .forEach(NotificationCenter.default.post)
  }
  
}
