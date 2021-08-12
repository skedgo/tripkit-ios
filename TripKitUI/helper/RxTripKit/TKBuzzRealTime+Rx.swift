//
//  TKBuzzRealTime+Rx.swift
//  TripKit
//
//  Created by Adrian Schönig on 03.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

import TripKit

extension Reactive where Base: TKBuzzRealTime {
  
  /// Stream real-time updates for the trip
  ///
  /// - Parameters:
  ///   - trip: The trip to update
  ///   - updateInterval: The frequency at which the trip should be updated (default is every 10 seconds)
  ///   - active: Optional stream whether updates should keep being performed, e.g., you can create a bunch of these, but only the active one will be updated. It's expected that these go back and forth between `true` and `false`
  ///
  /// - returns: Stream of the trip, *whenever* it gets updated, i.e., if there's no update the stream won't fire.
  public static func streamUpdates(_ trip: Trip, updateInterval: DispatchTimeInterval = .seconds(10), active: Observable<Bool> = .just(true)) -> Observable<Trip> {
    guard trip.wantsRealTimeUpdates else { return .never() }
    
    return active
      .flatMapLatest { active -> Observable<Int> in
        if active {
          return Observable<Int>
            .interval(updateInterval, scheduler: MainScheduler.instance)
            .startWith(0) // update as soon as we become active
        } else {
          return .never()
        }
      }
      .map { _ in trip }
      .filter { $0.managedObjectContext != nil && $0.wantsRealTimeUpdates }
      .flatMapLatest(Self.update)
      .filter { $1 }
      .map { trip, _ in trip }
  }
  
  
  /// Perform one-off real-time update of the provided trip
  ///
  /// No need to call this if `trip.wantsRealTimeUpdates == false`. It'd just complete immediately.
  ///
  /// - Parameter trip: The trip to update
  ///
  /// - returns: One-off callback with the update. Note that the `Trip` object returned in the callback will always be the same object provided to the method, i.e., trips are updated in-place.
  public static func update(_ trip: Trip) -> Single<(Trip, didUpdate: Bool)> {
    guard trip.wantsRealTimeUpdates else {
      TKLog.debug("Don't bother calling this for trips that don't want updates")
      return .just((trip, false))
    }
    
    return Single.create { subscriber in
      TKTripFetcher.update(trip) { result in
        subscriber(result.map { ($0.0, $0.didUpdate)} )
      }
      return Disposables.create()
    }
  }
  
  /// Perform one-off updates of the visible trips of each trip group
  ///
  /// - Parameter tripGroups: Trip groups, where only the visible trip will be updated
  ///
  /// - returns: Progress of the update, but it won't indicate which trips did get updated
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
