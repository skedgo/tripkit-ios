//
//  TKUITripGetOffAlertsViewModel.swift
//  TripKitUI-iOS
//
//  Created by Jules Ian Gilos on 1/7/23.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import TripKit

class TKUITripGetOffAlertsViewModel: NSObject {
  
  // Note: Should this be a separate view model or should this merge with TKUITripOverviewViewModel?
  
  public func enableAlerts(_ enable: Bool) {
    TKGeoMonitorManager.shared.setAlertsEnabled(enable)
  }
  
}
