//
//  TKUITripOverviewViewModel+Fetch.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 07.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

import TripKit

extension TKUITripOverviewViewModel {
  
  static func fetchContentOfServices(in trip: Trip) -> Observable<Void> {
    let queries: [(Service, Date, TKRegion)] = trip.segments
      .filter { !$0.isContinuation } // the previous segment will provide that
      .compactMap { $0.service != nil ? ($0.service!, $0.departureTime, $0.startRegion ?? trip.regionForRealTimeUpdates) : nil }
      .filter { $0.0.hasServiceData == false }
      
    let requests: [Observable<Void>] = queries
      .map(TKBuzzInfoProvider.rx.downloadContent)
      .map { $0.asObservable() }

    let merged = Observable<Void>.merge(requests)
    return merged.throttle(.milliseconds(500), latest: true, scheduler: MainScheduler.asyncInstance)
  }
  
}

