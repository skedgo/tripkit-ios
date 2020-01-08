//
//  NearbyMapManager+MapCenter.swift.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 30.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

extension TKUINearbyMapManager {
  
  fileprivate struct MapState {
    enum Mode {
      case takeNext
      case takeNone
    }
    
    var mode: Mode
    var center: CLLocationCoordinate2D
    
    init() {
      self.mode = .takeNext
      self.center = .invalid
    }
    
    mutating func update(trackingMode: MKUserTrackingMode, center: CLLocationCoordinate2D) {
      guard !MapState.centersEqual(center, self.center) else { return }
      
      switch (self.mode, trackingMode) {
      case (_, .none):
        self.center = center
        self.mode = .takeNext
      case (.takeNext, _):
        self.center = center
        self.mode = .takeNone
      case (.takeNone, _):
        self.mode = .takeNone
      }
    }
    
    static func centersEqual(_ first: CLLocationCoordinate2D, _ second: CLLocationCoordinate2D) -> Bool {
      return abs(first.latitude - second.latitude) < 0.00001
          && abs(first.longitude - second.longitude) < 0.00001
    }
  }
  
  static func buildMapCenter(tracking: Observable<MKUserTrackingMode>, center: Observable<CLLocationCoordinate2D>) -> Observable<CLLocationCoordinate2D?> {
    
    return Observable
      .combineLatest(tracking.startWith(.none), center)
      .scan(into: MapState()) { $0.update(trackingMode: $1.0, center: $1.1) }
      .distinctUntilChanged({ $0.center }, comparer: MapState.centersEqual)
      .map { $0.center.isValid ? $0.center : nil }
  }
  
}

