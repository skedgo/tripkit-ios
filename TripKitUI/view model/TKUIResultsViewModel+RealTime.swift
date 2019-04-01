//
//  TKUIResultsViewModel+RealTime.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 01.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

// MARK: - Real-time updates

extension TKUIResultsViewModel {
  
  static func fetchRealTimeUpdates(for tripGroups: Observable<[TripGroup]>, isVisible: Observable<Bool>) -> Observable<TKRealTimeUpdateProgress> {
    
    // We update when the timer fires and we're visible...
    let tick = Observable<Int>.interval(30, scheduler: MainScheduler.instance)
      .withLatestFrom(isVisible.startWith(true))
      .filter { $0 }
      .map { _ in }
    
    // ... or when we become visible
    let updateOnAppear = isVisible
      .filter { $0 }
      .map { _ in }
    
    // Then fire of the actual update (but not more often than once every X secs)
    return Observable.merge(tick, updateOnAppear)
      .throttle(15, scheduler: MainScheduler.instance)
      .withLatestFrom(tripGroups)
      .flatMapLatest(TKBuzzRealTime.rx.update)
      .startWith(.idle)
  }
  
}

extension Reactive where Base: TKBuzzRealTime {
  
  static func update(tripGroups: [TripGroup]) -> Observable<TKRealTimeUpdateProgress> {
    let trips = tripGroups
      .compactMap { $0.visibleTrip }
      .filter { $0.wantsRealTimeUpdates }
    
    let individualUpdates = trips.map(update).map { $0.asObservable() }
    return Observable
      .combineLatest(individualUpdates) { _ in .updated }
      .startWith(.updating)
  }
  
  private static func update(_ trip: Trip) -> Single<Bool> {
    guard trip.wantsRealTimeUpdates else {
      assertionFailure("Don't bother calling this for trips that don't want updates")
      return .just(false)
    }
    
    var helper: TKBuzzRouter! = TKBuzzRouter()
    return Single.create { subscriber in
      helper.update(trip) { _, didUpdate in
        subscriber(.success(didUpdate))
      }
      return Disposables.create {
        helper = nil
      }
    }
  }
  
}
