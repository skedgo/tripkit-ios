//
//  TKUIServiceViewModel+Fetch.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 18.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

import TripKit

// MARK: - Fetching service content

extension TKUIServiceViewModel {
  
  enum FetchError: Error {
    case couldNotFetchServiceContent
  }
  
  static func fetchServiceContent(embarkation: StopVisits) async throws {
    guard let service = embarkation.service, !service.hasServiceData, let region = embarkation.stop.region else {
      return
    }

    let response = try await TKBuzzInfoProvider.downloadContent(of: embarkation.service, embarkationDate: embarkation.timeForServerRequests, region: region)
    guard case .some((_, true)) = response else {
      throw FetchError.couldNotFetchServiceContent
    }
  }
  
}

// MARK: - Fetching real-time updates

extension TKUIServiceViewModel {
  
  private static let realTimeRefreshInterval: DispatchTimeInterval = .seconds(15)
  
  static func fetchRealTimeUpdates(embarkation: StopVisits) -> Observable<TKRealTimeUpdateProgress<Void>> {
    
    return Observable<Int>
      .interval(realTimeRefreshInterval, scheduler: MainScheduler.instance)
      .startWith(0) // update immediately
      .flatMapLatest { _ -> Observable<TKRealTimeUpdateProgress<Void>> in
        return TKRealTimeFetcher.rx
          .update(embarkation: embarkation)
          .asObservable()
          .map { _ in .updated(()) }
          .startWith(.updating)
      }
      .startWith(.idle)
  }
}

extension Reactive where Base: TKRealTimeFetcher {
  
  static func update(embarkation: StopVisits) -> Single<Void> {
    guard let region = embarkation.stop.region else {
      return .never()
    }
    
    return Single.create { subscriber in
      TKRealTimeFetcher.update([embarkation.service], in: region) { result in
        subscriber(result.map { _ in } )
      }
      return Disposables.create()
    }
    
  }
  
}
