//
//  TKBuzzRouter+Rx.swift
//  Pods
//
//  Created by Adrian Schoenig on 30/08/2016.
//
//

import Foundation

import RxSwift
import RxCocoa

extension TKBuzzRouter {
  enum Error: Swift.Error {
    case downloadFailed
  }
}

extension Reactive where Base : TKBuzzRouter {
  
  public func downloadTrip(_ url: URL, identifier: String? = nil, into context: NSManagedObjectContext) -> Observable<Trip> {
    return Observable.create { observer in
      self.base.downloadTrip(url, identifier: identifier, intoTripKitContext: context) { trip in
        if let trip = trip {
          observer.onNext(trip)
          observer.onCompleted()
        } else {
          observer.onError(TKBuzzRouter.Error.downloadFailed)
        }
      }
      return Disposables.create()
    }
  }
  
}
