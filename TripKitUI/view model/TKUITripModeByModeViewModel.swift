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

extension Notification.Name {
  public static let TKTripUpdatedNotification = Notification.Name("TKTripUpdatedNotification")
}

class TKUITripModeByModeViewModel {
  
  init(trip: Trip) {
    self.realTimeUpdate = TKUITripModeByModeViewModel.fetchRealTime(for: trip)
    
    self.tripDidUpdate = NotificationCenter.default.rx
      .notification(.TKTripUpdatedNotification, object: trip)
      .compactMap { $0.object as? Trip }
      .asSignal(onErrorSignalWith: .empty())
  }
  
  let realTimeUpdate: Driver<TKRealTimeUpdateProgress<Trip>>
  
  let tripDidUpdate: Signal<Trip>
  
  private static func fetchRealTime(for trip: Trip) -> Driver<TKRealTimeUpdateProgress<Trip>> {
    guard trip.wantsRealTimeUpdates else { return .empty() }
    
    return Observable<Int>.interval(.seconds(10), scheduler: MainScheduler.instance)
      .flatMapLatest { _ -> Observable<TKRealTimeUpdateProgress<Trip>> in
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
