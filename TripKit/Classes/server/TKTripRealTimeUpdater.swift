//
//  TKTripRealTimeUpdater.swift
//  TripKit
//
//  Created by Adrian Schoenig on 3/11/16.
//
//

import Foundation

import RxSwift
import RxRelay

/// Helper class that manages real-time updates for trips. Also handles
/// switching to a different trip.
public class TKTripRealTimeUpdater {
  
  public init(trip: Trip? = nil, timeBetweenUpdates: DispatchTimeInterval = .seconds(10)) {
    tripVar = BehaviorRelay(value: trip)
    
    let currentTrip = tripVar.asObservable().filter { $0 != nil }.map { $0! }.distinctUntilChanged()
    let enabled = enabledVar.asObservable().distinctUntilChanged()
    let tick = Observable<Int>.interval(timeBetweenUpdates, scheduler: MainScheduler.instance)

    Observable.combineLatest(currentTrip, enabled, tick) { trip, enabled, _ in (trip, enabled) }
      .filter { trip, enabled in
        return enabled && trip.managedObjectContext != nil && trip.wantsRealTimeUpdates
      }
      .map { _ in }
      .subscribe(onNext: { [unowned self] in
        self.update()
      })
      .disposed(by: disposeBag)
  }
  
  private let realTime = TKBuzzRealTime()

  private var tripVar: BehaviorRelay<Trip?>
  private var enabledVar = BehaviorRelay(value: true)
  private var updated = PublishSubject<Trip>()
  private let disposeBag = DisposeBag()

  /// The trip which is getting updated with real-time data
  public var trip: Trip? {
    get { return tripVar.value }
    set { tripVar.accept(newValue) }
  }
  
  /// Whether real-time updates are enabled at all (regardless of whether
  /// the trip is cabable, i.e., this can return `true` even through the
  /// trip doesn't support real-time updates).
  public var isEnabled: Bool {
    get { return enabledVar.value }
    set { enabledVar.accept(newValue) }
  }
  
  /// Observable sequence that is triggered whenever the trip has been
  /// updated with real-time data.
  public var rx_updated: Observable<Trip> { return updated }
  
  private func update() {
    guard let trip = trip else { preconditionFailure() }
    realTime.update(
      trip,
      success: { [weak self] updated, didUpdate in
        guard didUpdate, updated == self?.trip else { return }
        self?.updated.onNext(updated)
      },
      failure: { error in
        TKLog.info("TKTripRealTimeUpdater", text: "Error: \(String(describing: error))")
      })
  }
  
}
