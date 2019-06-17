//
//  TKUITripOverviewViewModel+Fetch.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 07.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

extension TKUITripOverviewViewModel {
  
  static func fetchContentOfServices(in trip: Trip) -> Observable<Void> {
    let requests = trip.segments
      .compactMap { $0.service != nil ? ($0.service!, $0.departureTime, $0.startRegion ?? trip.regionForRealTimeUpdates) : nil }
      .filter { $0.0.hasServiceData == false }
      .map(TKBuzzInfoProvider.rx.downloadContent)
      .map { $0.asObservable() }

    let merged = Observable<Void>.merge(requests)
    return merged.throttle(.milliseconds(500), latest: true, scheduler: MainScheduler.asyncInstance)
  }
  
}

extension Reactive where Base == TKBuzzInfoProvider {
  
  fileprivate static func downloadContent(of service: Service, forEmbarkationDate date: Date, in region: TKRegion) -> Single<Void> {
    return Single.create { subscriber in
      var provider: TKBuzzInfoProvider! = TKBuzzInfoProvider()
      
      provider.downloadContent(of: service, forEmbarkationDate: date, in: region) { service, success in
        if success {
          subscriber(.success(()))
        } else {
          subscriber(.error(TKError(code: 87612, message: "Could not download service data.")))
        }
      }
      
      return Disposables.create {
        provider = nil
      }
    }
  }
  
}
