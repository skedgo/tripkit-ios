//
//  TKUITripModeByModeCard+ViewModel.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 01.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

extension TKUITripModeByModeCard {
  
  static func notifyOfUpdates(in trip: Trip) {
    trip.segments.map { Notification(name: .TKUIUpdatedRealTimeData, object: $0) }
      .forEach(NotificationCenter.default.post)
  }
  
}
