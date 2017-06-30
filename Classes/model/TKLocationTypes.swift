//
//  TKLocations.swift
//  Pods
//
//  Created by Adrian Schoenig on 5/12/16.
//
//

import Foundation

import Marshal
import RxSwift



public class TKBikePodLocation: STKModeCoordinate {
  
  fileprivate let rx_bikePodVar: Variable<TKBikePodInfo>
  
  /// Detailed bike-pod related information.
  ///
  /// - Note: Can change if real-time data is available. Recommended to use
  ///         `rx.bikePod` instead.
  public var bikePod: TKBikePodInfo {
    get { return rx_bikePodVar.value }
    set { rx_bikePodVar.value = newValue }
  }
  
  public required init(object: MarshaledObject) throws {
    let info: TKBikePodInfo = try object.value(for: "bikePod")
    rx_bikePodVar = Variable(info)
    try super.init(object: object)
  }
  
  public required init?(coder aDecoder: NSCoder) {
    guard let info: TKBikePodInfo = aDecoder.decodeOrUnmarshal(forKey: "bikePod") else { return nil }
    rx_bikePodVar = Variable(info)
    super.init(coder: aDecoder)
  }
  
  override public func encode(with aCoder: NSCoder) {
    super.encode(with: aCoder)
    aCoder.encode(bikePod.marshaled(), forKey: "bikePod")
  }
}

extension Reactive where Base : TKBikePodLocation {
  public var bikePod: Observable<TKBikePodInfo> {
    return base.rx_bikePodVar.asObservable()
  }
}


public class TKCarPodLocation: STKModeCoordinate {
  
  fileprivate let rx_carPodVar: Variable<TKCarPodInfo>
  
  /// Detailed car-pod related information.
  ///
  /// - Note: Can change if real-time data is available. Recommended to use
  ///         `rx.carPod` instead.
  public var carPod: TKCarPodInfo {
    get { return rx_carPodVar.value }
    set { rx_carPodVar.value = newValue }
  }
  
  public required init(object: MarshaledObject) throws {
    let info: TKCarPodInfo = try object.value(for: "carPod")
    rx_carPodVar = Variable(info)
    try super.init(object: object)
  }
  
  public required init?(coder aDecoder: NSCoder) {
    guard let info: TKCarPodInfo = aDecoder.decodeOrUnmarshal(forKey: "carPod") else { return nil }
    rx_carPodVar = Variable(info)
    super.init(coder: aDecoder)
  }
  
  override public func encode(with aCoder: NSCoder) {
    super.encode(with: aCoder)
    aCoder.encode(carPod.marshaled(), forKey: "carPod")
  }
}

extension Reactive where Base : TKCarPodLocation {
  public var carPod: Observable<TKCarPodInfo> {
    return base.rx_carPodVar.asObservable()
  }
}


public class TKCarParkLocation: STKModeCoordinate {
  
  fileprivate let rx_carParkVar: Variable<TKCarParkInfo>
  
  /// Detailed car-park related information.
  ///
  /// - Note: Can change if real-time data is available. Recommended to use
  ///         `rx.carPark` instead.
  public var carPark: TKCarParkInfo {
    get { return rx_carParkVar.value }
    set { rx_carParkVar.value = newValue }
  }
  
  public required init(object: MarshaledObject) throws {
    let info: TKCarParkInfo = try object.value(for: "carPark")
    rx_carParkVar = Variable(info)
    try super.init(object: object)
  }
  
  public required init?(coder aDecoder: NSCoder) {
    guard let info: TKCarParkInfo = aDecoder.decodeOrUnmarshal(forKey: "carPark") else { return nil }
    rx_carParkVar = Variable(info)
    super.init(coder: aDecoder)
  }

  override public func encode(with aCoder: NSCoder) {
    super.encode(with: aCoder)
    aCoder.encode(carPark.marshaled(), forKey: "carPark")
  }
}

extension Reactive where Base : TKCarParkLocation {
  public var carPark: Observable<TKCarParkInfo> {
    return base.rx_carParkVar.asObservable()
  }
}


public class TKCarRentalLocation: STKModeCoordinate {
  
  public let carRental: TKCarRentalInfo
  
  public required init(object: MarshaledObject) throws {
    carRental = try object.value(for: "carRental")
    try super.init(object: object)
  }
  
  public required init?(coder aDecoder: NSCoder) {
    guard let info: TKCarRentalInfo = aDecoder.decodeOrUnmarshal(forKey: "carRental") else { return nil }
    carRental = info
    super.init(coder: aDecoder)
  }
  
  override public func encode(with aCoder: NSCoder) {
    super.encode(with: aCoder)
    aCoder.encode(carRental.marshaled(), forKey: "carRental")
  }
}
