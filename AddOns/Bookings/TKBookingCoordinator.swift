//
//  TKBookingCoordinator.swift
//  TripKit
//
//  Created by Adrian Schoenig on 24/11/16.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

#if TK_NO_FRAMEWORKS
#else
  import TripKit
#endif

public protocol TKBookingCoordinator {
  
  associatedtype Bookable
  
  var rx_bookingUI: Observable<(Bookable, TKBookingStateMachine)> { get }
  
  func didBecomeActive()
  
  func didDismiss()
  
  func didVisitDisregardURL()
  
  func bookingCompleted(with url: URL?)
  
  func handle(_ url: URL) -> Bool

}
