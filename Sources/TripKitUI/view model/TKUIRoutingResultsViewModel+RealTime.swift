//
//  TKUIRoutingResultsViewModel+RealTime.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 01.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

import TripKit

// MARK: - Real-time updates

extension TKUIRoutingResultsViewModel {
  
  static func fetchRealTimeUpdates(for tripGroups: Observable<[TripGroup]>) -> Observable<TKRealTimeUpdateProgress<Void>> {
    return Observable<Int>.interval(.seconds(30), scheduler: MainScheduler.instance)
      .withLatestFrom(tripGroups)
      .flatMapLatest(TKRealTimeFetcher.rx.update)
      .startWith(.idle)
  }
  
}
