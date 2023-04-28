//
//  TKUITripMonitorManager+Rx.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 28/4/2023.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

@available(iOS 14.0, *)
extension TKUITripMonitorManager {
  
  var rx_monitoredTrip: Observable<MonitoredTrip?> {
    $monitoredTrip.asObservable()
  }
  
}
