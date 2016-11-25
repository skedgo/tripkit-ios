//
//  TKBookingCoordinator.swift
//  TripGo
//
//  Created by Adrian Schoenig on 24/11/16.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import TripKit

public protocol TKBookingCoordinator {
  
  var rx_bookingUI: Observable<(TKSegment, TKBookingStateMachine)> { get }
  
  func didBecomeActive()
  
  func didDismiss()
  
  func didVisitDisregardURL()
  
  func bookingCompleted(with url: URL)
  
  func handle(_ url: URL) -> Bool

}
