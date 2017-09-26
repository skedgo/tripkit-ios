//
//  BaseAPIModels.swift
//  TripKit
//
//  Created by Adrian Schoenig on 22.09.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

import Marshal // Deprecated, but still in use

extension API {
  
  public struct CompanyInfo : Codable, Unmarshaling, Marshaling {
    public let name: String
    public let website: URL?
    public let phone: String?
    public let remoteIcon: String?
    public let remoteDarkIcon: String?
    public let color: RGBColor?
    
    public init(object: MarshaledObject) throws {
      name            = try  object.value(for: "name")
      website         = try? object.value(for: "website")
      phone           = try? object.value(for: "phone")
      remoteIcon      = try? object.value(for: "remoteIcon")
      remoteDarkIcon  = try? object.value(for: "remoteDarkIcon")
      color           = try? object.value(for: "color")
    }
    
    public typealias MarshalType = [String: Any]
    
    public func marshaled() -> MarshalType {
      var marshaled: MarshalType =  [
        "name": name,
        ]
      
      marshaled["website"] = website
      marshaled["phone"] = phone
      marshaled["remoteIcon"] = remoteIcon
      marshaled["remoteDarkIcon"] = remoteDarkIcon
      marshaled["color"] = color
      return marshaled
    }
  }
  
  public struct DataAttribution : Codable, Unmarshaling, Marshaling {
    public let provider: CompanyInfo
    public let disclaimer: String?
    
    public init(object: MarshaledObject) throws {
      provider    = try  object.value(for: "provider")
      disclaimer  = try? object.value(for: "disclaimer")
    }
    
    public typealias MarshalType = [String: Any]
    
    public func marshaled() -> MarshalType {
      var marshaled : MarshalType =  [
        "provider": provider.marshaled(),
      ]
      marshaled["disclaimer"] = disclaimer
      return marshaled
    }
  }
  
  public struct Location: Codable {
    let lat: CLLocationDegrees
    let lng: CLLocationDegrees
    let bearing: CLLocationDirection?
    let name: String?
    let address: String?
  }
  
  public enum RealTimeStatus: String, Codable {
    case capable    = "CAPABLE"
    case incapable  = "INCAPABLE"
    
    case isRealTime = "IS_REAL_TIME"
    case canceled   = "CANCELLED"
  }

  public struct RGBColor: Codable, Unmarshaling, Marshaling {
    let red: Int
    let green: Int
    let blue: Int
    
    var color: SGKColor {
      return SGKColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: 1)
    }
    
    public init?(for color: SGKColor) {
      var red: CGFloat = 0
      var green: CGFloat = 0
      var blue: CGFloat = 0
      if color.getRed(&red, green: &green, blue: &blue, alpha: nil) {
        self.red = Int(red * 255)
        self.green = Int(green * 255)
        self.blue = Int(blue * 255)
      } else {
        return nil
      }
    }
    
    public init(object: MarshaledObject) throws {
      red   = try  object.value(for: "red")
      green = try  object.value(for: "green")
      blue  = try  object.value(for: "blue")
    }
    
    public typealias MarshalType = [String: Any]
    
    public func marshaled() -> MarshalType {
      return [
        "red": red,
        "green": green,
        "blue": blue,
      ]
    }
  }
  
  public struct Vehicle: Codable {
    
    /// Representation of real-time occupancy information for public transport
    public enum Occupancy: String, Codable {
      case unknown = "UNKNOWN"
      case empty = "EMPTY"
      case manySeatsAvailable = "MANY_SEATS_AVAILABLE"
      case fewSeatsAvailable = "FEW_SEATS_AVAILABLE"
      case standingRoomOnly = "STANDING_ROOM_ONLY"
      case crushedStandingRoomOnly = "CRUSHED_STANDING_ROOM_ONLY"
      case full = "FULL"
      case notAcceptingPassengers = "NOT_ACCEPTING_PASSENGERS"
    }
    
    let location: Location
    
    let id: String?
    let label: String?
    let icon: URL?
    let lastUpdate: TimeInterval?
    let occupancy: Occupancy?
    let wifi: Bool?
  }
  
}

// MARK: - Convenience helpers

extension API.Vehicle.Occupancy {
  
  public var color: SGKColor? {
    
    switch self {
    case .unknown:
      return nil
    case .empty, .manySeatsAvailable:
      return SGKColor(red: 23/255.0, green: 177/255.0, blue: 94/255.0, alpha: 1)
    case .fewSeatsAvailable:
      return SGKColor(red: 255/255.0, green: 181/255.0, blue: 0/255.0, alpha: 1)
    case .standingRoomOnly, .crushedStandingRoomOnly:
      return SGKColor(red: 255/255.0, green: 150/255.0, blue: 0/255.0, alpha: 1)
    case .full, .notAcceptingPassengers:
      return SGKColor(red: 255/255.0, green: 75/255.0, blue: 71/255.0, alpha: 1)
    }
    
  }
  
  public var description: String? {
    switch self {
    case .unknown: return nil
    case .empty: return NSLocalizedString("Empty", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "As in 'this bus/train is empty'")
    case .manySeatsAvailable: return NSLocalizedString("Many seats available", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "As in 'this bus/train has many seats available'")
    case .fewSeatsAvailable: return NSLocalizedString("Few seats available", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "As in 'this bus/train has few seats available'")
    case .standingRoomOnly: return NSLocalizedString("Standing room only", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "As in 'this bus/train is fairly full and has standing room only'")
    case .crushedStandingRoomOnly: return NSLocalizedString("Limited standing room only", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "As in 'this bus/train is so full, there's only limited standing room'")
    case .full: return NSLocalizedString("Full", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "As in 'this bus/train is full and likely can't accept further passengers'")
    case .notAcceptingPassengers: return NSLocalizedString("Not accepting passengers", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "As in 'this bus/train is full and definitely not accepting further passengers'")
    }
  }
  
  public init(intValue: Int) {
    switch intValue {
    case 1: self = .empty
    case 2: self = .manySeatsAvailable
    case 3: self = .fewSeatsAvailable
    case 4: self = .standingRoomOnly
    case 5: self = .crushedStandingRoomOnly
    case 6: self = .full
    case 7: self = .notAcceptingPassengers
    default: self = .unknown
    }
  }
  
  var intValue: Int {
    get {
      switch self {
      case .unknown: return 0
      case .empty: return 1
      case .manySeatsAvailable: return 2
      case .fewSeatsAvailable: return 3
      case .standingRoomOnly: return 4
      case .crushedStandingRoomOnly: return 5
      case .full: return 6
      case .notAcceptingPassengers: return 7
      }
    }
  }
  
}

extension API.CompanyInfo {
  
  public var remoteIconURL: URL? {
    guard let fileNamePart = remoteIcon else {
      return nil
    }
    
    return SVKServer.imageURL(forIconFileNamePart: fileNamePart, of: .listMainMode)
  }
  
  public var remoteDarkIconURL: URL? {
    guard let fileNamePart = remoteDarkIcon else {
      return nil
    }
    
    return SVKServer.imageURL(forIconFileNamePart: fileNamePart, of: .listMainMode)
  }
  
}

// MARK: - Marshal helper

extension Date: ValueType {
  public static func value(from object: Any) throws -> Date {
    guard let seconds = object as? TimeInterval else {
      throw MarshalError.typeMismatch(expected: TimeInterval.self, actual: type(of: object))
    }
    return Date(timeIntervalSince1970: seconds)
  }
}