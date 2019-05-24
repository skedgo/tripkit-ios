//
//  TKUIServiceViewModel+Fetch.swift
//  TripGoAppKit
//
//  Created by Adrian Schönig on 18.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

// MARK: - Fetching service content

extension TKUIServiceViewModel {
  
  enum FetchError: Error {
    case couldNotFetchServiceContent
    case unknownError
  }
  
  static func fetchServiceContent(embarkation: StopVisits) -> Single<Void> {
    
    let service = embarkation.service
    guard !service.hasServiceData else {
      return .just((), scheduler: MainScheduler.instance)
    }
    
    return Single.create { subscriber in
      var infoProvider: TKBuzzInfoProvider! = TKBuzzInfoProvider()
      infoProvider.downloadContent(of: embarkation.service, forEmbarkationDate: embarkation.timeForServerRequests, in: embarkation.stop.region) { service, success in
        if success {
          subscriber(.success(()))
        } else {
          subscriber(.error(FetchError.couldNotFetchServiceContent))
        }
      }
      return Disposables.create {
        infoProvider = nil
      }
    }.observeOn(MainScheduler.instance)
    
  }
  
}

// MARK: - Fetching real-time updates

extension TKUIServiceViewModel {
  
  private static let realTimeRefreshInterval: DispatchTimeInterval = .seconds(15)
  
  static func fetchRealTimeUpdates(embarkation: StopVisits) -> Observable<TKRealTimeUpdateProgress<Void>> {
    
    return Observable<Int>
      .interval(realTimeRefreshInterval, scheduler: MainScheduler.instance)
      .flatMapLatest { _ -> Observable<TKRealTimeUpdateProgress<Void>> in
        return TKBuzzRealTime.rx
          .update(embarkation: embarkation)
          .asObservable()
          .map { _ in .updated(()) }
          .startWith(.updating)
      }
      .startWith(.idle)
  }
}

extension Reactive where Base: TKBuzzRealTime {
  
  static func update(embarkation: StopVisits) -> Single<Void> {
    guard let region = embarkation.stop.region else {
      return .never()
    }
    
    return Single.create { subscriber in
      TKBuzzRealTime.update(
        [embarkation.service],
        in: region,
        success: { _ in
          subscriber(.success(()))
        },
        failure: { error in
          subscriber(.error(error ?? TKUIServiceViewModel.FetchError.unknownError))
        }
      )
      return Disposables.create()
    }
    
  }
  
}
