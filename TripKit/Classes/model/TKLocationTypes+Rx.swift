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
  public var bikePod: Observable<API.BikePodInfo> {
    return base.rx
      .observeWeakly(API.BikePodInfo.self, "bikePod")
      .compactMap { $0 }
  }
}

extension Reactive where Base : TKCarPodLocation {
  public var carPod: Observable<API.CarPodInfo> {
    return base.rx
      .observeWeakly(API.CarPodInfo.self, "carPod")
      .compactMap { $0 }
  }
}

extension Reactive where Base : TKCarParkLocation {
  public var carPark: Observable<API.CarParkInfo> {
    return base.rx
      .observeWeakly(API.CarParkInfo.self, "carPark")
      .compactMap { $0 }
  }
}

extension Reactive where Base : TKFreeFloatingVehicleLocation {
  public var vehicle: Observable<API.FreeFloatingVehicleInfo> {
    return base.rx
      .observeWeakly(API.FreeFloatingVehicleInfo.self, "vehicle")
      .compactMap { $0 }
  }
}
