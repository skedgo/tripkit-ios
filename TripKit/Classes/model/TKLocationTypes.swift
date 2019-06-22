//
//  TKLocations.swift
//  TripKit
//
//  Created by Adrian Schoenig on 5/12/16.
//
//

import Foundation

import RxSwift
import RxRelay

public class TKBikePodLocation: TKModeCoordinate {
  
  fileprivate let rx_bikePodVar: BehaviorRelay<API.BikePodInfo>
  
  /// Detailed bike-pod related information.
  ///
  /// - Note: Can change if real-time data is available. Recommended to use
  ///         `rx.bikePod` instead.
  public var bikePod: API.BikePodInfo {
    get { return rx_bikePodVar.value }
    set { rx_bikePodVar.accept(newValue) }
  }
  
  private enum CodingKeys: String, CodingKey {
    case bikePod
  }
  
  public required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let info = try values.decode(API.BikePodInfo.self, forKey: .bikePod)
    rx_bikePodVar = BehaviorRelay(value: info)
    try super.init(from: decoder)
    locationID = info.identifier
  }
  
  public override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(bikePod, forKey: .bikePod)
  }
  
  public required init?(coder aDecoder: NSCoder) {
    guard let info = try? aDecoder.decode(API.BikePodInfo.self, forKey: "bikePod") else { return nil }
    rx_bikePodVar = BehaviorRelay(value: info)
    super.init(coder: aDecoder)
    locationID = info.identifier
  }
  
  public override func encode(with aCoder: NSCoder) {
    super.encode(with: aCoder)
    try? aCoder.encode(encodable: bikePod, forKey: "bikePod")
  }

}

extension Reactive where Base : TKBikePodLocation {
  public var bikePod: Observable<API.BikePodInfo> {
    return base.rx_bikePodVar.asObservable()
  }
}


public class TKCarPodLocation: TKModeCoordinate {
  
  fileprivate let rx_carPodVar: BehaviorRelay<API.CarPodInfo>
  
  /// Detailed car-pod related information.
  ///
  /// - Note: Can change if real-time data is available. Recommended to use
  ///         `rx.carPod` instead.
  public var carPod: API.CarPodInfo {
    get { return rx_carPodVar.value }
    set { rx_carPodVar.accept(newValue) }
  }
  
  public var supportsVehicleAvailability: Bool {
    guard let mode = carPod.availabilityMode else { return false }
    return mode != .none
  }
  
  private enum CodingKeys: String, CodingKey {
    case carPod
  }
  
  public required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let info = try values.decode(API.CarPodInfo.self, forKey: .carPod)
    rx_carPodVar = BehaviorRelay(value: info)
    try super.init(from: decoder)
    locationID = info.identifier
  }
  
  public override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(carPod, forKey: .carPod)
  }

  public required init?(coder aDecoder: NSCoder) {
    guard let info = try? aDecoder.decode(API.CarPodInfo.self, forKey: "carPod") else { return nil }
    rx_carPodVar = BehaviorRelay(value: info)
    super.init(coder: aDecoder)
    locationID = info.identifier
  }
  
  public override func encode(with aCoder: NSCoder) {
    super.encode(with: aCoder)
    try? aCoder.encode(encodable: carPod, forKey: "carPod")
  }
  
}

extension Reactive where Base : TKCarPodLocation {
  public var carPod: Observable<API.CarPodInfo> {
    return base.rx_carPodVar.asObservable()
  }
}


public class TKCarParkLocation: TKModeCoordinate {
  
  fileprivate let rx_carParkVar: BehaviorRelay<API.CarParkInfo>
  
  /// Detailed car-park related information.
  ///
  /// - Note: Can change if real-time data is available. Recommended to use
  ///         `rx.carPark` instead.
  public var carPark: API.CarParkInfo {
    get { return rx_carParkVar.value }
    set { rx_carParkVar.accept(newValue) }
  }
  
  private enum CodingKeys: String, CodingKey {
    case carPark
  }
  
  public required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let info = try values.decode(API.CarParkInfo.self, forKey: .carPark)
    rx_carParkVar = BehaviorRelay(value: info)
    try super.init(from: decoder)
    locationID = info.identifier
  }
  
  public override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(carPark, forKey: .carPark)
  }
  
  public required init?(coder aDecoder: NSCoder) {
    guard let info = try? aDecoder.decode(API.CarParkInfo.self, forKey: "carPark") else { return nil }
    rx_carParkVar = BehaviorRelay(value: info)
    super.init(coder: aDecoder)
    locationID = info.identifier
  }
  
  public override func encode(with aCoder: NSCoder) {
    super.encode(with: aCoder)
    try? aCoder.encode(encodable: carPark, forKey: "carPark")
  }

}

extension Reactive where Base : TKCarParkLocation {
  public var carPark: Observable<API.CarParkInfo> {
    return base.rx_carParkVar.asObservable()
  }
}


public class TKCarRentalLocation: TKModeCoordinate {
  
  public let carRental: API.CarRentalInfo
  
  private enum CodingKeys: String, CodingKey {
    case carRental
  }
  
  public required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    carRental = try values.decode(API.CarRentalInfo.self, forKey: .carRental)
    try super.init(from: decoder)
    locationID = carRental.identifier
  }
  
  public override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(carRental, forKey: .carRental)
  }
  
  public required init?(coder aDecoder: NSCoder) {
    guard let info = try? aDecoder.decode(API.CarRentalInfo.self, forKey: "carRental") else { return nil }
    carRental = info
    super.init(coder: aDecoder)
    locationID = carRental.identifier
  }
  
  public override func encode(with aCoder: NSCoder) {
    super.encode(with: aCoder)
    try? aCoder.encode(encodable: carRental, forKey: "carRental")
  }

}

public class TKFreeFloatingVehicleLocation: TKModeCoordinate {
  
  fileprivate let rx_infoVar: BehaviorRelay<API.FreeFloatingVehicleInfo>
  
  /// Detailed car-pod related information.
  ///
  /// - Note: Can change if real-time data is available. Recommended to use
  ///         `rx.carPod` instead.
  public var vehicle: API.FreeFloatingVehicleInfo {
    get { return rx_infoVar.value }
    set { rx_infoVar.accept(newValue) }
  }
  
  private enum CodingKeys: String, CodingKey {
    case vehicle
  }
  
  public required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let info = try values.decode(API.FreeFloatingVehicleInfo.self, forKey: .vehicle)
    rx_infoVar = BehaviorRelay(value: info)
    try super.init(from: decoder)
    locationID = info.identifier
  }
  
  public override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(vehicle, forKey: .vehicle)
  }
  
  public required init?(coder aDecoder: NSCoder) {
    guard let info = try? aDecoder.decode(API.FreeFloatingVehicleInfo.self, forKey: "vehicle") else { return nil }
    rx_infoVar = BehaviorRelay(value: info)
    super.init(coder: aDecoder)
    locationID = info.identifier
  }
  
  public override func encode(with aCoder: NSCoder) {
    super.encode(with: aCoder)
    try? aCoder.encode(encodable: vehicle, forKey: "vehicle")
  }
  
}

extension Reactive where Base : TKFreeFloatingVehicleLocation {
  public var vehicle: Observable<API.FreeFloatingVehicleInfo> {
    return base.rx_infoVar.asObservable()
  }
}


extension NSCoder {
  
  enum CoderError: Error {
    case keyIsNotData(String)
  }
  
  func decode<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T {
    guard let data = decodeObject(forKey: key) as? Data
      else { throw CoderError.keyIsNotData(key) }
    return try JSONDecoder().decode(type, from: data)
  }

  func encode<T: Encodable>(encodable value: T, forKey key: String) throws {
    let data = try JSONEncoder().encode(value)
    encode(data, forKey: key)
  }

}

// MAKR: - DeepLink

public protocol TKDeepLinkable {
  var deepLink: URL? { get }
  var downloadLink: URL? { get }
}

extension TKDeepLinkable {
  public var deepLink: URL? { return nil }
  public var downloadLink: URL? { return nil }
}

extension TKBikePodLocation: TKDeepLinkable {
  public var deepLink: URL? {
    return bikePod.deepLink
  }
  public var downloadLink: URL? {
    return bikePod.operatorInfo.appInfo?.downloadURL
  }
}

extension TKCarPodLocation: TKDeepLinkable {
  public var deepLink: URL? {
    return carPod.deepLink
  }
  public var downloadLink: URL? {
    return carPod.operatorInfo.appInfo?.downloadURL
  }
}

extension TKCarParkLocation: TKDeepLinkable {
  public var deepLink: URL? {
    return carPark.deepLink
  }
  public var downloadLink: URL? {
    return carPark.operatorInfo?.appInfo?.downloadURL
  }
}

extension TKCarRentalLocation: TKDeepLinkable {
  public var downloadLink: URL? {
    return carRental.company.appInfo?.downloadURL
  }
}

extension TKFreeFloatingVehicleLocation: TKDeepLinkable {
  public var downloadLink: URL? {
    return vehicle.operatorInfo.appInfo?.downloadURL
  }
}
