//
//  Loc+TripKit.swift
//  Pods
//
//  Created by Adrian Schoenig on 30/11/16.
//
//

import Foundation

import SGCoreKit

extension Loc {
  
  public static var Trip: String {
    return NSLocalizedString("Trip", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Title for a trip")
  }
  
  public static var OpeningHours: String {
    return NSLocalizedString("Opening Hours", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Title for opening hours")
  }
  
  public static var PublicHoliday: String {
    return NSLocalizedString("Public holiday", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "")
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
      let format = NSLocalizedString("%@ stops", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Number of stops before you get off a vehicle, e.g., '10 stops'. (old key: Stops)")
      return String(format: format, NSNumber(value: count))
    }
  }

  
}
