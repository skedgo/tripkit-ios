//
//  TKLocations.swift
//  TripKit
//
//  Created by Adrian Schoenig on 5/12/16.
//
//

import Foundation

import RxSwift

public class TKBikePodLocation: TKModeCoordinate {
  
  fileprivate let rx_bikePodVar: Variable<API.BikePodInfo>
  
  /// Detailed bike-pod related information.
  ///
  /// - Note: Can change if real-time data is available. Recommended to use
  ///         `rx.bikePod` instead.
  public var bikePod: API.BikePodInfo {
    get { return rx_bikePodVar.value }
    set { rx_bikePodVar.value = newValue }
  }
  
  private enum CodingKeys: String, CodingKey {
    case bikePod
  }
  
  public required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let info = try values.decode(API.BikePodInfo.self, forKey: .bikePod)
    rx_bikePodVar = Variable(info)
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
    rx_bikePodVar = Variable(info)
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
  
  fileprivate let rx_carPodVar: Variable<API.CarPodInfo>
  
  /// Detailed car-pod related information.
  ///
  /// - Note: Can change if real-time data is available. Recommended to use
  ///         `rx.carPod` instead.
  public var carPod: API.CarPodInfo {
    get { return rx_carPodVar.value }
    set { rx_carPodVar.value = newValue }
  }
  
  private enum CodingKeys: String, CodingKey {
    case carPod
  }
  
  public required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let info = try values.decode(API.CarPodInfo.self, forKey: .carPod)
    rx_carPodVar = Variable(info)
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
    rx_carPodVar = Variable(info)
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
  
  fileprivate let rx_carParkVar: Variable<API.CarParkInfo>
  
  /// Detailed car-park related information.
  ///
  /// - Note: Can change if real-time data is available. Recommended to use
  ///         `rx.carPark` instead.
  public var carPark: API.CarParkInfo {
    get { return rx_carParkVar.value }
    set { rx_carParkVar.value = newValue }
  }
  
  private enum CodingKeys: String, CodingKey {
    case carPark
  }
  
  public required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let info = try values.decode(API.CarParkInfo.self, forKey: .carPark)
    rx_carParkVar = Variable(info)
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
    rx_carParkVar = Variable(info)
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
  }
  
  public override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(carRental, forKey: .carRental)
    locationID = carRental.identifier
  }
  
  public required init?(coder aDecoder: NSCoder) {
    guard let info = try? aDecoder.decode(API.CarRentalInfo.self, forKey: "carRental") else { return nil }
    carRental = info
    super.init(coder: aDecoder)
  }
  
  public override func encode(with aCoder: NSCoder) {
    super.encode(with: aCoder)
    try? aCoder.encode(encodable: carRental, forKey: "carRental")
    locationID = carRental.identifier
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
