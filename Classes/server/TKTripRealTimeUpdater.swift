//
//  TKTripRealTimeUpdater.swift
//  Pods
//
//  Created by Adrian Schoenig on 3/11/16.
//
//

import Foundation

import RxSwift

public class TKTripRealTimeUpdater {
  
  public init(trip: Trip? = nil) {
    tripVar = Variable(trip)
    
    let currentTrip = tripVar.asObservable().filter { $0 != nil }.map { $0! }.distinctUntilChanged()
    let enabled = enabledVar.asObservable().distinctUntilChanged()
    let tick = Observable<Int>.interval(timeBetweenUpdates, scheduler: MainScheduler.instance)

    Observable.combineLatest(currentTrip, enabled, tick) { trip, enabled, _ in (trip, enabled) }
      .filter { trip, enabled in
        return enabled && trip.managedObjectContext != nil && trip.wantsRealTimeUpdates()
      }
      .map { _ in }
      .subscribe(onNext: update)
      .addDisposableTo(disposeBag)
  }
  
  private let realTime = TKBuzzRealTime()
  private let timeBetweenUpdates: TimeInterval = 10

  private var tripVar: Variable<Trip?>
  private var enabledVar = Variable(true)
  private var updated = PublishSubject<Trip>()
  private let disposeBag = DisposeBag()

  public var trip: Trip? {
    get { return tripVar.value }
    set { tripVar.value = newValue }
  }
  
  public var isEnabled: Bool {
    get { return enabledVar.value }
    set { enabledVar.value = newValue }
  }
  
  public var rx_updated: Observable<Trip> { return updated }
  
  private func update() {
    guard let trip = trip else { preconditionFailure() }
    realTime.update(
      trip,
      success: { [weak self] updated, didUpdate in
        guard didUpdate, let updated = updated, updated == self?.trip else { return }
        self?.updated.onNext(updated)
      },
      failure: { error in
        SGKLog.info("TKTripRealTimeUpdater", text: "Error: \(error)")
      })
  }
  
  
}
