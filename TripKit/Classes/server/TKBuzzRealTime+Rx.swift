//
//  TKBuzzRealTime+Rx.swift
//  TripKit
//
//  Created by Adrian Schönig on 03.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

extension Reactive where Base: TKBuzzRealTime {

  public static func update(_ trip: Trip) -> Single<(Trip, didUpdate: Bool)> {
    guard trip.wantsRealTimeUpdates else {
      assertionFailure("Don't bother calling this for trips that don't want updates")
      return .just((trip, false))
    }
    
    var helper: TKBuzzRouter! = TKBuzzRouter()
    return Single.create { subscriber in
      helper.update(trip) { newTrip, didUpdate in
        subscriber(.success((newTrip, didUpdate)))
      }
      return Disposables.create {
        helper = nil
      }
    }
  }

  public static func update(tripGroups: [TripGroup]) -> Observable<TKRealTimeUpdateProgress<Void>> {
    let trips = tripGroups
      .compactMap { $0.visibleTrip }
      .filter { $0.wantsRealTimeUpdates }
    
    let individualUpdates = trips
      .map(TKBuzzRealTime.rx.update)
      .map { $0.asObservable() }
    
    return Observable
      .combineLatest(individualUpdates) { _ in .updated(()) }
      .startWith(.updating)
  }

}
