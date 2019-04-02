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
  
  static func fetchRealTimeUpdates(for tripGroups: Observable<[TripGroup]>) -> Observable<TKRealTimeUpdateProgress> {    
    return Observable<Int>.interval(30, scheduler: MainScheduler.instance)
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
    
    let individualUpdates = trips
      .map(TKBuzzRouter.rx.update)
      .map { $0.asObservable() }
    
    return Observable
      .combineLatest(individualUpdates) { _ in .updated }
      .startWith(.updating)
  }
  
}
