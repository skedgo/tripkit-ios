//
//  TKRouter+Rx.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/08/2016.
//
//

import Foundation
import CoreData

import RxSwift

import TripKit

extension TKTripFetcher: @retroactive ReactiveCompatible {}
extension Reactive where Base == TKTripFetcher {
  public static func downloadTrip(_ url: URL, identifier: String? = nil, into context: NSManagedObjectContext) -> Single<Trip> {
    return Single.create { observer in
      TKTripFetcher.downloadTrip(url, identifier: identifier, into: context, completion: observer)
      return Disposables.create()
    }
  }
  
  public static func update(_ trip: Trip, url: URL? = nil, aborter: @escaping ((URL) -> Bool) = { _ in false }) -> Single<Bool> {
    return Single.create { observer in
      TKTripFetcher.update(trip, url: url, aborter: aborter) { result in
        observer(result.map(\.didUpdate))
      }
      return Disposables.create()
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
          subscriber(.failure(error))
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
