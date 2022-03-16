//
//  TKBuzzInfoProvider+Rx.swift
//  TripKit
//
//  Created by Adrian Schönig on 30.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

import TripKit

extension TKBuzzInfoProvider: ReactiveCompatible {}

extension Reactive where Base == TKBuzzInfoProvider {
  
  /**
   Asynchronously fetches transit alerts for the provided region using Rx.
   */
  public static func fetchTransitAlerts(forRegion region: TKRegion) -> Single<[TKAPI.Alert]> {
    return fetchTransitAlertMappings(forRegion: region)
      .map { $0.map {$0.alert} }
  }
  
  public static func fetchTransitAlertMappings(forRegion region: TKRegion) -> Single<[TKAPI.AlertMapping]> {
    let paras: [String: Any] = [
      "region": region.name,
      "v": TKSettings.parserJsonVersion
    ]
    
    return TKServer.shared.rx
      .hit(TKBuzzInfoProvider.AlertsTransitResponse.self, path: "alerts/transit.json", parameters: paras, region: region)
      .map { _, _, model in
        model.alerts
      }
  }
  
}
