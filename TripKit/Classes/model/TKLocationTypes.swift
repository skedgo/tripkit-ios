//
//  TKLocations.swift
//  TripKit
//
//  Created by Adrian Schoenig on 5/12/16.
//
//

import Foundation

public class TKBikePodLocation: TKModeCoordinate {
  
  /// Detailed bike-pod related information.
  ///
  /// - Note: Can change if real-time data is available. So use KVO or Rx.
  public var bikePod: API.BikePodInfo
  
  private enum CodingKeys: String, CodingKey {
    case bikePod
  }
  
  public required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    bikePod = try values.decode(API.BikePodInfo.self, forKey: .bikePod)
    try super.init(from: decoder)
    locationID = bikePod.identifier
  }
  
  public override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(bikePod, forKey: .bikePod)
  }
  
  public required init?(coder aDecoder: NSCoder) {
    guard let info = try? aDecoder.decode(API.BikePodInfo.self, forKey: "bikePod") else { return nil }
    bikePod = info
    super.init(coder: aDecoder)
    locationID = info.identifier
  }
  
  public override func encode(with aCoder: NSCoder) {
    super.encode(with: aCoder)
    try? aCoder.encode(encodable: bikePod, forKey: "bikePod")
  }

}



public class TKCarPodLocation: TKModeCoordinate {
  
  /// Detailed car-pod related information.
  ///
  /// - Note: Can change if real-time data is available. So use KVO or Rx.
  public var carPod: API.CarPodInfo
  
  public var supportsVehicleAvailability: Bool {
    return carPod.availabilityMode != .none
  }
  
  private enum CodingKeys: String, CodingKey {
    case carPod
  }
  
  public required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    carPod = try values.decode(API.CarPodInfo.self, forKey: .carPod)
    try super.init(from: decoder)
    locationID = carPod.identifier
  }
  
  public override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(carPod, forKey: .carPod)
  }

  public required init?(coder aDecoder: NSCoder) {
    guard let info = try? aDecoder.decode(API.CarPodInfo.self, forKey: "carPod") else { return nil }
    carPod = info
    super.init(coder: aDecoder)
    locationID = info.identifier
  }
  
  public override func encode(with aCoder: NSCoder) {
    super.encode(with: aCoder)
    try? aCoder.encode(encodable: carPod, forKey: "carPod")
  }
  
}

public class TKCarParkLocation: TKModeCoordinate {
  
  /// Detailed car-park related information.
  ///
  /// - Note: Can change if real-time data is available. So use KVO or Rx.
  public var carPark: API.CarParkInfo
  
  private enum CodingKeys: String, CodingKey {
    case carPark
  }
  
  public required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    carPark = try values.decode(API.CarParkInfo.self, forKey: .carPark)
    try super.init(from: decoder)
    locationID = carPark.identifier
  }
  
  public override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(carPark, forKey: .carPark)
  }
  
  public required init?(coder aDecoder: NSCoder) {
    guard let info = try? aDecoder.decode(API.CarParkInfo.self, forKey: "carPark") else { return nil }
    carPark = info
    super.init(coder: aDecoder)
    locationID = info.identifier
  }
  
  public override func encode(with aCoder: NSCoder) {
    super.encode(with: aCoder)
    try? aCoder.encode(encodable: carPark, forKey: "carPark")
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
  
  /// Detailed car-pod related information.
  ///
  /// - Note: Can change if real-time data is available. So use KVO or Rx.
  public var vehicle: API.FreeFloatingVehicleInfo
  
  private enum CodingKeys: String, CodingKey {
    case vehicle
  }
  
  public required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    vehicle = try values.decode(API.FreeFloatingVehicleInfo.self, forKey: .vehicle)
    try super.init(from: decoder)
    locationID = vehicle.identifier
  }
  
  public override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(vehicle, forKey: .vehicle)
  }
  
  public required init?(coder aDecoder: NSCoder) {
    guard let info = try? aDecoder.decode(API.FreeFloatingVehicleInfo.self, forKey: "vehicle") else { return nil }
    vehicle = info
    super.init(coder: aDecoder)
    locationID = info.identifier
  }
  
  public override func encode(with aCoder: NSCoder) {
    super.encode(with: aCoder)
    try? aCoder.encode(encodable: vehicle, forKey: "vehicle")
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
