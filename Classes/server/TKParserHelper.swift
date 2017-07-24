//
//  TKParserHelper.swift
//  TripKit
//
//  Created by Adrian Schoenig on 17/10/16.
//
//

import Foundation

extension TKParserHelper {

  @objc(insertNewVehicle:inTripKitContext:)
  public static func insertNewVehicle(from dict: [String: Any], into context: NSManagedObjectContext) -> Vehicle {
    return Vehicle(dict: dict, into: context)
  }
  
  
  @objc(updateVehicle:fromDictionary:)
  public static func update(vehicle: Vehicle, from dict: [String: Any]) {
    vehicle.update(with: dict)
  }
  
  
  @objc(vehiclesPayloadForVehicles:)
  public static func vehiclesPayload(for vehicles: [STKVehicular]) -> [[String: Any]] {
    return vehicles.map(STKVehicularHelper.skedGoFullDictionary(forVehicle:))
  }
  
  
  @objc(segmentVisibilityType:)
  public static func segmentVisibilityType(for string: String) -> STKTripSegmentVisibility {
    switch string {
    case "in summary": return .inSummary
    case "on map": return .onMap
    case "in details": return .inDetails
    default: return .hidden
    }
  }
  
  public static func parseDate(_ object: Any?) -> Date? {
    if let string = object as? String {
      return try? Date(iso8601: string)
    } else if let interval = object as? TimeInterval, interval > 0 {
      return Date(timeIntervalSince1970: interval)
    } else {
      return nil
    }
  }
  

}

extension Vehicle {
  
  fileprivate convenience init(dict: [String: Any], into context: NSManagedObjectContext) {
    if #available(iOS 10.0, macOS 10.12, *) {
      self.init(context: context)
    } else {
      self.init(entity: NSEntityDescription.entity(forEntityName: "Vehicle", in: context)!, insertInto: context)
    }
    update(with: dict)
  }
  
  fileprivate func update(with dict: [String: Any]) {
    identifier = dict["id"] as? String
    label = dict["label"] as? String
    icon = dict["icon"] as? String

    if let date = TKParserHelper.parseDate(dict["lastUpdate"]) {
      lastUpdate = date
    } else {
      assertionFailure("Vehicle is missing last update. Falling back to now.")
      lastUpdate = Date()
    }
    
    if let occupancyString = dict["occupancy"] as? String {
      occupancy = TKOccupancy(occupancyString)
    } else {
      occupancy = .unknown
    }

    // Location info
    if let location = dict["location"] as? [String: Any], let lat = location["lat"] as? Double, let lng = location["lng"] as? Double {
      latitude = NSNumber(value: lat)
      longitude = NSNumber(value: lng)
      if let degrees = location["bearing"] as? Double {
        bearing = NSNumber(value: degrees)
      }
    }
    
  }
  
}

extension TKOccupancy {
  
  fileprivate init(_ raw: String) {
    self = {
      switch raw {
      case "EMPTY": return .empty
      case "MANY_SEATS_AVAILABLE": return .manySeatsAvailable
      case "FEW_SEATS_AVAILABLE": return .fewSeatsAvailable
      case "STANDING_ROOM_ONLY": return .standingRoomOnly
      case "CRUSHED_STANDING_ROOM_ONLY": return .crushedStandingRoomOnly
      case "FULL": return .full
      case "NOT_ACCEPTING_PASSENGERS": return .notAcceptingPassengers
      default: return .unknown
      }
    }()
  }
  
}
