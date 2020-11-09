//
//  Vehicle+Rx.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 01.11.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

extension Reactive where Base: Vehicle {
  
  public var components: Observable<([[TKAPI.VehicleComponents]], Date)> {
    return observeWeakly(NSData.self, "componentsData")
      .map { [weak base] _ in
        let components = base?.components ?? [[]]
        let date = base?.lastUpdate ?? Date()
        return (components, date)
      }
  }
  
}
