//
//  TKPostBookingCoordinator.swift
//  TripGo
//
//  Created by Adrian Schoenig on 24/11/16.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import TripKit

public class TKPostBookingCoordinator {

  fileprivate let segment: TKSegment
  fileprivate let stateMachine: Variable<TKBookingStateMachine>
  fileprivate let disposeBag = DisposeBag()
  
  
  public init(startAt url: URL, for segment: TKSegment) {
    self.segment = segment
    stateMachine = Variable(.fetchingBookingForm(url, data: nil))
    
    let mode = segment.modeIdentifier() ?? "mode_is_irrelevant_here_anyway"

    // This is where we do the actual transitions
    
    self.stateMachine.asObservable()
      .flatMap { fsm in
        TKBookingTransitioner.transition(state: fsm, forMode: mode)
      }
      .subscribe(
        onNext: { [weak self] newState in
          self?.stateMachine.value = newState
        }, onError: { error in
          assertionFailure("It should never error out but did with: \(error). Instead, you should use the `.error` case of `TKBookingStateMachine`")
        }
      )
      .addDisposableTo(disposeBag)
  }

}


extension TKPostBookingCoordinator : TKBookingCoordinator {
 
  public var rx_bookingUI: Observable<(TKSegment, TKBookingStateMachine)> {
    return stateMachine.asObservable().map { (self.segment, $0) }
  }
  
  public func didBecomeActive() {
    stateMachine.value.appDidBecomeActive()
  }
  
  public func didDismiss() {
    stateMachine.value.appDidBecomeActive()
  }
  
  public func didVisitDisregardURL() {
    stateMachine.value.userOpenedDisregardURL()
  }
  
  public func bookingCompleted(with url: URL) {
    stateMachine.value.formCompletedBooking(url: url)
  }
  
  public func handle(_ url: URL) -> Bool {
    let previousValue = stateMachine.value
    stateMachine.value.appHandleCallback(url)
    
    return previousValue != stateMachine.value
  }
  
}
