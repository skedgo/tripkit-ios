//
//  TKUITripMonitorManager+Rx.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 28/4/2023.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

import TripKit

@MainActor
@available(iOS 14.0, *)
extension Reactive where Base == TKUITripMonitorManager {

  var monitoredTrip: Infallible<TKUITripMonitorManager.MonitoredTrip?> {
    base.$monitoredTrip
      .asObservable()
      .observe(on: MainScheduler.instance)
      .asInfallible { _ in .empty() }
  }
  
  public var trip: Infallible<Trip?> {
    monitoredTrip
      .map { monitored in
        guard let tripURL = monitored?.tripURL else { return nil }
        let candidate = Trip.find(tripURL: tripURL, in: TripKit.shared.tripKitContext)
        guard candidate?.tripId != nil, candidate?.departureTime != nil else { return nil } // Since deleted
        return candidate
      }
  }
  
}
