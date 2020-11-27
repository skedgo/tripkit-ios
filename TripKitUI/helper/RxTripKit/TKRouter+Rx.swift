//
//  TKRouter+Rx.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/08/2016.
//
//

import Foundation

import RxSwift

extension TKTripFetcher {
  enum FetchError : Error {
    case downloadFailed
  }
}

extension Reactive where Base : TKTripFetcher {
  public static func downloadTrip(_ url: URL, identifier: String? = nil, into context: NSManagedObjectContext) -> Single<Trip> {
    return Single.create { observer in
      var fetcher: TKTripFetcher! = TKTripFetcher()
      fetcher.downloadTrip(url, identifier: identifier, intoTripKitContext: context) { trip in
        if let trip = trip {
          observer(.success(trip))
        } else {
          observer(.error(TKTripFetcher.FetchError.downloadFailed))
        }
      }
      return Disposables.create {
        fetcher = nil
      }
    }
  }
}
 
extension Reactive where Base : TKRouter {
  public static func fetchBestTrip<C>(for request: TripRequest, modes: C) -> Single<Trip> where C: Collection, C.Element == String {
    var router: TKRouter! = TKRouter()
    if !modes.isEmpty {
      router.modeIdentifiers = Set(modes)
    }
    return Single.create { subscriber in
      router.fetchBestTrip(for: request) { result in
        switch result {
        case .failure(let error):
          subscriber(.error(error))
        case .success(let trip):
          subscriber(.success(trip))
        }
      }
      
      return Disposables.create {
        router = nil
      }
    }
  }
  
}
