//
//  Loc+TripKit.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/11/16.
//
//

import Foundation

extension Loc {
  
  @objc public static var Trip: String {
    return NSLocalizedString("Trip", tableName: "TripKit", bundle: .tripKit, comment: "Title for a trip")
  }

  @objc public static var NoPlannedTrips: String {
    return NSLocalizedString("No planned trips", tableName: "TripKit", bundle: .tripKit, comment: "Indicating no trips have been planned within the next 24 hrs")
  }
  
  @objc public static var OpeningHours: String {
    return NSLocalizedString("Opening Hours", tableName: "TripKit", bundle: .tripKit, comment: "Title for opening hours")
  }
  
  @objc public static var PublicHoliday: String {
    return NSLocalizedString("Public holiday", tableName: "TripKit", bundle: .tripKit, comment: "")
  }
  
  public static var Show: String {
    return NSLocalizedString("Show", tableName: "TripKit", bundle: .tripKit, comment: "Title for button that, when tapped, shows something, e.g., a list of alert")
  }
  
  // MARK: - Linking to TSP
  
  @objc public static var Disconnect: String {
    return NSLocalizedString("Disconnect", tableName: "TripKit", bundle: .tripKit, comment: "To disconnect/unlink from a service provider, e.g., Uber")
  }
  
  @objc public static var Setup: String {
    return NSLocalizedString("Setup", tableName: "TripKit", bundle: .tripKit, comment: "Set up to connect/link to a service provider, e.g., Uber")
  }
  
  // MARK: - Accessibility
  
  public static var FriendlyPath: String {
    return NSLocalizedString("Friendly", tableName: "TripKit", bundle: .tripKit, comment: "Indicating a path is wheelchair/cycyling friendly")
  }
  
  public static var UnfriendlyPath: String {
    return NSLocalizedString("Unfriendly", tableName: "TripKit", bundle: .tripKit, comment: "Indicating a path is wheelchair/cycyling unfriendly")
  }
  
  public static var UnknownPathFriendliness: String {
    return NSLocalizedString("Unknown", tableName: "TripKit", bundle: .tripKit, comment: "Indicating the wheelchair/cycling friendliness of a path is unknown")
  }
  
  // MARK: - Format

  @objc(ArriveAtDate:)
  public static func ArriveAt(date: String) -> String {
    let format = NSLocalizedString("Arrive at %@", tableName: "TripKit", bundle: .tripKit, comment: "'%@' will be replaced with the arrival time. (old key: ArrivalTime)")
    return String(format: format, date)
  }
  
  @objc(FromLocation:)
  public static func From(location from: String) -> String {
    let format = NSLocalizedString("From %@", tableName: "TripKit", bundle: .tripKit, comment: "Departure location. (old key: PrimaryLocationStart)")
    return String(format: format, from)
  }

  @objc(ToLocation:)
  public static func To(location to: String) -> String {
    let format = NSLocalizedString("To %@", tableName: "TripKit", bundle: .tripKit, comment: "Destination location. For trip titles, e.g., 'To work'. (old key: PrimaryLocationEnd)")
    return String(format: format, to)
  }

  @objc public static func To(from: String, to: String) -> String {
    let format = NSLocalizedString("%@ to %@", tableName: "TripKit", bundle: .tripKit, comment: "For describing a time interval, e.g., '8:30 to 8:43'")
    return String(format: format, from, to)
  }
  
  @objc(Stops:)
  public static func Stops(_ count: Int) -> String {
    switch count {
    case 0: return ""
      
    case 1: return NSLocalizedString("1 stop", tableName: "TripKit", bundle: .tripKit, comment: "Number of stops before you get off a stop, if there's just 1 stop.")
      
    default:
      let format = NSLocalizedString("%@ stops", tableName: "TripKit", bundle: .tripKit, comment: "Number of stops before you get off a vehicle, if there are 2 stops or more, e.g., '10 stops'. (old key: Stops)")
      return String(format: format, NSNumber(value: count))
    }
  }
  
  public static func Alerts(_ count: Int) -> String? {
    guard count > 1 else {
      return nil
    }
    
    let format = NSLocalizedString("%@ alerts", tableName: "TripKit", bundle: .tripKit, comment: "Number of alerts, in this case, there are multiple (plural")
    return String(format: format, NSNumber(value: count))
  }

}

extension Bundle {
  
  @objc public static let tripKit: Bundle = TKTripKit.bundle()
  
}
