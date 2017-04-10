//
//  TripBookingCoordinator.swift
//  TripGo
//
//  Created by Adrian Schoenig on 31/10/16.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

import SGBookingKit

public enum TKTripBookingCoordinatorError : Error {
  
  case segmentNoLongerAvailable
  
}

/// Coordinates initiation of trip bookings.The coordinator class for initiating and 
///
/// It is the gateway for the `TripViewModel` to the booking
/// logic. You monitor the booking state using `rx_bookingUI`
/// and pass on user interactions via the various functions.
///
/// The actual work of sending requests is delegated to
/// `TKBookingTransitioner`.
///
/// - note: The trip *can* change
public class TripBookingCoordinator {
  
  public init(trip: Trip?) {
    self.trip = trip
  }
  
  
  public var trip: Trip? {
    
    didSet {
      stateMachines = nil
      disposeBag = DisposeBag()
      
      guard let trip = trip else { return }

      // we build both our state machine, and our combined list
      // of observables of UI state changes.
      var machines = [Int : Variable<TKBookingStateMachine>]()
      let fsmPublisher = PublishSubject<(Int, TKBookingStateMachine)>()
      for (segmentIndex, segment) in trip.segments().enumerated() {
        guard segment.bookingQuickInternalURL() != nil else { continue }
        
        // Note: We're not restoring waiting state in here. That's
        //   left as an exercise to whoever is using this class.
        //   E.g., TripViewModel is doing that.
        
        let selectionIndex = segment.activeIndexQuickBooking ?? 0
        let variable = Variable(TKBookingStateMachine.viewingQuickBooking(selectionIndex))
        
        machines[segmentIndex] = variable
        variable.asObservable()
          .distinctUntilChanged() // Otherwise staying in the same state would trigger again
          .map { (segmentIndex, $0) }
          .bind(to: fsmPublisher)
          .addDisposableTo(disposeBag)
      }
      
      guard !machines.isEmpty else { return }

      stateMachines = machines
      
      fsmPublisher
        .map { [weak self] index, fsm in
          guard let segment = self?.trip?.segments()[index] else {
            return nil
          }
          return (segment, fsm)
        }
        .filter { $0 != nil }.map { $0! }
        .bind(to: publisher)
        .addDisposableTo(disposeBag)
      
      // This is where we do the actual transitions
      fsmPublisher
        .map { [weak self] index, fsm -> (TKBookingStateMachine, String, Int) in
          guard
            let segment = self?.trip?.segments()[index],
            let mode = segment.modeIdentifier()
            else {
            throw TKTripBookingCoordinatorError.segmentNoLongerAvailable
          }
          return (fsm, mode, index)
        }
        
        // Get the next state
        .flatMap { fsm, mode, index -> Observable<(TKBookingStateMachine, Int)> in
          return TKBookingTransitioner.transition(state: fsm, forMode: mode)
            .map { ($0, index) }
        }
        
        // We switch to the next step on the main scheduler as otherwise we can hit
        // re-entrancy issues in RxSwift.
        .observeOn(MainScheduler.asyncInstance)
        .subscribe(
          onNext: { [weak self] newState, index in
            guard let machine = self?.stateMachines?[index] else { preconditionFailure() }
            machine.value = newState
          }, onError: { error in
            assertionFailure("It should never error out but did with: \(error). Instead, you should use the `.error` case of `TKBookingStateMachine`")
          }
        )
        .addDisposableTo(disposeBag)
    }
    
  }
  

  fileprivate var stateMachines: [Int : Variable<TKBookingStateMachine>]? = nil
  
  fileprivate let publisher = PublishSubject<(TKSegment, TKBookingStateMachine)>()
  
  fileprivate var disposeBag = DisposeBag()
  
  fileprivate func machine(for segment: TKSegment) -> Variable<TKBookingStateMachine>? {
    guard let index = trip?.segments().index(of: segment) else { return nil }
    return stateMachines?[index]
  }
  
  
  public func state(for segment: TKSegment) -> TKBookingStateMachine? {
    return machine(for: segment)?.value
  }
  
  
  public func enter(_ state: TKBookingStateMachine, for segment: TKSegment) {
    guard let machine = machine(for: segment) else { return }
    machine.value = state
  }
  
  
  public func isWaiting(for segment: TKSegment) -> Bool {
    guard let machine = machine(for: segment) else { return false }
    
    switch machine.value {
    case .fetchingBookingForm, .authorizing, .authCallbackRetrieved, .authAppBecameActive, .authWaitingForCallback:
      return true
    default:
      return false
    }
  }

  
  public func selectedOption(at index: Int, for segment: TKSegment) {
    guard let machine = machine(for: segment) else { return }
    machine.value.userPicked(selection: index)
  }
  

  public func requestedBooking(with url: URL, for segment: TKSegment, sender: Any?) {
    guard let machine = machine(for: segment) else { return }
    machine.value.userStartedBooking(url: url, sender: sender)
  }
  
}


extension TripBookingCoordinator : TKBookingCoordinator {
  
  public var rx_bookingUI: Observable<(TKSegment, TKBookingStateMachine)> {
    return publisher
  }
  

  public func didBecomeActive() {
    guard let machines = stateMachines else { return }
    for (_, machineVar) in machines {
      machineVar.value.appDidBecomeActive()
    }
  }
  
  
  public func didDismiss() {
    guard let machines = stateMachines else { return }
    for (_, machineVar) in machines {
      machineVar.value.userDidDismiss()
    }
  }

  
  public func didVisitDisregardURL() {
    guard let machines = stateMachines else { return }
    for (_, machineVar) in machines {
      machineVar.value.userOpenedDisregardURL()
    }
  }
  
  
  public func bookingCompleted(with url: URL?) {
    guard let machines = stateMachines else { return }
    for (_, machineVar) in machines {
      machineVar.value.formCompletedBooking(url: url)
    }
  }
  

  public func handle(_ url: URL) -> Bool {
    guard let machines = stateMachines else { return false }
    
    for (_, machineVar) in machines {
      machineVar.value.appHandleCallback(url)
    }
    return true
  }
  
}
