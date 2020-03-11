//
//  TKUITripRealtimeUpdater.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 11/3/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

class TKUITripRealtimeUpdater {
  
  init(trip: Trip, updateInterval: DispatchTimeInterval = .seconds(10)) {
    
    let realTime = TKBuzzRealTime()
    
    latest = Observable<Int>.interval(updateInterval, scheduler: MainScheduler.instance)
      .map { _ in trip }
      .filter { $0.managedObjectContext != nil && $0.wantsRealTimeUpdates }
      .flatMap(realTime.rx.update)
    
  }
  
  let latest: Observable<Trip>
  
}

extension Reactive where Base: TKBuzzRealTime {
  
  func update(trip: Trip) -> Single<Trip> {
    Single.create { single in
      
      self.base.update(trip, success: { (updatedTrip, didUpdate) in
        single(.success(updatedTrip))
      }) { (optionalError) in
        guard let error = optionalError else { return }
        single(.error(error))
      }
      
      return Disposables.create()
    }
  }
  
}
