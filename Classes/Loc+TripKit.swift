//
//  Loc+TripKit.swift
//  Pods
//
//  Created by Adrian Schoenig on 30/11/16.
//
//

import Foundation

extension Loc {
  
  public static var Trip: String {
    return NSLocalizedString("Trip", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Title for a trip")
  }

  public static var NoPlannedTrips: String {
    return NSLocalizedString("No planned trips", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Indicating no trips have been planned within the next 24 hrs")
  }
  
  public static var OpeningHours: String {
    return NSLocalizedString("Opening Hours", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Title for opening hours")
  }
  
  public static var PublicHoliday: String {
    return NSLocalizedString("Public holiday", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "")
  }
  
  // MARK: - Linking to TSP
  
  public static var Disconnect: String {
    return NSLocalizedString("Disconnect", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "To disconnect/unlink from a service provider, e.g., Uber")
  }
  
  public static var Setup: String {
    return NSLocalizedString("Setup", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Set up to connect/link to a service provider, e.g., Uber")
  }
  
  
  // MARK: - Format

  @objc(ArriveAtDate:)
  public static func ArriveAt(date: String) -> String {
    let format = NSLocalizedString("Arrive at %@", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "'%@' will be replaced with the arrival time. (old key: ArrivalTime)")
    return String(format: format, date)
  }
  
  @objc(From:)
  public static func From(_ from: String) -> String {
    let format = NSLocalizedString("From %@", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Departure location. (old key: PrimaryLocationStart)")
    return String(format: format, from)
  }

  @objc(To:)
  public static func To(_ to: String) -> String {
    let format = NSLocalizedString("To %@", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Destination location. For trip titles, e.g., 'To work'. (old key: PrimaryLocationEnd)")
    return String(format: format, to)
  }
  
  @objc(Stops:)
  public static func Stops(_ count: Int) -> String {
    switch count {
    case 0: return ""
      
    case 1: return NSLocalizedString("1 stop", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Number of stops before you get off a stop, if there's just 1 stop.")
      
    default:
      let format = NSLocalizedString("%@ stops", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Number of stops before you get off a vehicle, if there are 2 stops or more, e.g., '10 stops'. (old key: Stops)")
      return String(format: format, NSNumber(value: count))
    }
  }

  
}
