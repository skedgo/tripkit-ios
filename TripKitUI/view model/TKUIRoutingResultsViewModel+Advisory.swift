//
//  TKUIRoutingResultsViewModel+Advisory.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 21.04.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import RxSwift

extension TKUIRoutingResultsViewModel {
  
  static func fetchAdvisory(for request: Observable<TripRequest>) -> Observable<TKAPI.Alert?> {
    
    return request
      .map(\.toLocation)
      .flatMapLatest {
        TKLocationRealTime
          .streamRealTime(for: $0)
          .take(1)
      }
      .map(\.alerts?.first)
  }
  
}
