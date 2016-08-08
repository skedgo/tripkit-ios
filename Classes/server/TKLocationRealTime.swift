//
//  TKLocationRealTime.swift
//  Pods
//
//  Created by Adrian Schoenig on 8/08/2016.
//
//

import Foundation

import RxSwift

public protocol RealTimeInfo {
  var localizedTitle: String { get }
}

public enum TKLocationRealTime {
  
  private struct CarParkInfo : RealTimeInfo {
    let available: Int
    
    var localizedTitle: String {
      let format = NSLocalizedString("%@ available", comment: "Availability indicator for a car park")
      return String(format: format, available.description) // TODO: Use number formatter
    }
  }
  
  public static func rx_fetchRealTime(locationId: String) -> Observable<RealTimeInfo> {
    return Observable.just(CarParkInfo(available: 5))
  }
}
