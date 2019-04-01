//
//  TKBuzzRouter+Rx.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/08/2016.
//
//

import Foundation

import RxSwift

extension TKBuzzRouter {
  enum RouterError : Error {
    case downloadFailed
    case noTripFound
  }
}

extension Reactive where Base : TKBuzzRouter {
  
  public func downloadTrip(_ url: URL, identifier: String? = nil, into context: NSManagedObjectContext) -> Single<Trip> {
    return Single.create { observer in
      self.base.downloadTrip(url, identifier: identifier, intoTripKitContext: context) { trip in
        if let trip = trip {
          observer(.success(trip))
        } else {
          observer(.error(TKBuzzRouter.RouterError.downloadFailed))
        }
      }
      return Disposables.create()
    }
  }
  
  public static func fetchBestTrip(for request: TripRequest) -> Single<Trip> {
    var router: TKBuzzRouter! = TKBuzzRouter()
    return Single.create { subscriber in
      router.fetchBestTrip(for: request, success: { request, _ in
        if let best = request.sortedVisibleTrips().first {
          subscriber(.success(best))
        } else {
          subscriber(.error(TKBuzzRouter.RouterError.noTripFound))
        }
      }, failure: { error, _ in
        subscriber(.error(error))
      })
      
      return Disposables.create {
        router = nil
      }
    }
  }
  
}
