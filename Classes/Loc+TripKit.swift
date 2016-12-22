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
  
}
