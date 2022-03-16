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
      .compactMap { $0.service != nil ? ($0.service!, $0.departureTime, $0.startRegion ?? .international) : nil }
      .filter { $0.0.hasServiceData == false }
      
    let requests: [Observable<Void>] = queries
      .map { query in
        Single.create {
          return try await TKBuzzInfoProvider.downloadContent(of: query.0, embarkationDate: query.1, region: query.2)
        }
        .asObservable()
        .compactMap { $0 }
        .map { _ in }
      }

    let merged = Observable<Void>.merge(requests)
    return merged.throttle(.milliseconds(500), latest: true, scheduler: MainScheduler.asyncInstance)
  }
  
}

