//
//  TKModeBookingCoordinator.swift
//  TripGo
//
//  Created by Adrian Schoenig on 24/11/16.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import TripKit

public class TKModeBookingCoordinator {

  fileprivate let mode: String
  fileprivate let stateMachine: Variable<TKBookingStateMachine>
  fileprivate let disposeBag = DisposeBag()
  
  
  public init(startAt url: URL, forMode mode: String) {
    self.mode = mode
    stateMachine = Variable(.fetchingBookingForm(url, data: nil, sender: nil))

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


extension TKModeBookingCoordinator : TKBookingCoordinator {
 
  public var rx_bookingUI: Observable<(String, TKBookingStateMachine)> {
    return stateMachine.asObservable().map { (self.mode, $0) }
  }
  
  public func didBecomeActive() {
    stateMachine.value.appDidBecomeActive()
  }
  
  public func didDismiss() {
    stateMachine.value.userDidDismiss()
  }
  
  public func didVisitDisregardURL() {
    stateMachine.value.userOpenedDisregardURL()
  }
  
  public func bookingCompleted(with url: URL?) {
    stateMachine.value.formCompletedBooking(url: url)
  }
  
  public func handle(_ url: URL) -> Bool {
    let previousValue = stateMachine.value
    stateMachine.value.appHandleCallback(url)
    
    return previousValue != stateMachine.value
  }
  
}
