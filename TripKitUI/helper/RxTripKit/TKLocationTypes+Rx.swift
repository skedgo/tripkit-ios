//
//  TKLocationTypes+Rx.swift
//  TripKit
//
//  Created by Adrian Schönig on 11.06.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

extension Reactive where Base : TKBikePodLocation {
  public var bikePod: Observable<TKAPI.BikePodInfo> {
    return base.rx
      .observeWeakly(TKAPI.BikePodInfo.self, "bikePod")
      .compactMap { $0 }
  }
}

extension Reactive where Base : TKCarPodLocation {
  public var carPod: Observable<TKAPI.CarPodInfo> {
    return base.rx
      .observeWeakly(TKAPI.CarPodInfo.self, "carPod")
      .compactMap { $0 }
  }
}

extension Reactive where Base : TKCarParkLocation {
  public var carPark: Observable<TKAPI.CarParkInfo> {
    return base.rx
      .observeWeakly(TKAPI.CarParkInfo.self, "carPark")
      .compactMap { $0 }
  }
}

extension Reactive where Base : TKFreeFloatingVehicleLocation {
  public var vehicle: Observable<TKAPI.SharedVehicleInfo> {
    return base.rx
      .observeWeakly(TKAPI.SharedVehicleInfo.self, "vehicle")
      .compactMap { $0 }
  }
}
