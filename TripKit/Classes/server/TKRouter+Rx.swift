//
//  TKRouter+Rx.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/08/2016.
//
//

import Foundation

import RxSwift

extension TKRouter {
  enum RouterError : Error {
    case downloadFailed
    case noTripFound
  }
}

extension Reactive where Base : TKRouter {
  
  public func downloadTrip(_ url: URL, identifier: String? = nil, into context: NSManagedObjectContext) -> Single<Trip> {
    return Single.create { observer in
      self.base.downloadTrip(url, identifier: identifier, intoTripKitContext: context) { trip in
        if let trip = trip {
          observer(.success(trip))
        } else {
          observer(.error(TKRouter.RouterError.downloadFailed))
        }
      }
      return Disposables.create()
    }
  }
  
  public static func fetchBestTrip<C>(for request: TripRequest, modes: C) -> Single<Trip> where C: Collection, C.Element == String {
    var router: TKRouter! = TKRouter()
    if !modes.isEmpty {
      router.modeIdentifiers = Set(modes)
    }
    return Single.create { subscriber in
      router.fetchBestTrip(for: request, success: { request, _ in
        if let best = request.sortedVisibleTrips().first {
          subscriber(.success(best))
        } else {
          subscriber(.error(TKRouter.RouterError.noTripFound))
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
