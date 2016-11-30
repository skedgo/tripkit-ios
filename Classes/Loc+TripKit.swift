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
  
  public static let Trip = NSLocalizedString("Trip", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Title for a trip")
  
  
  // MARK: - Format
  
  @objc(From:)
  public static func From(_ from: String) -> String {
    let format = NSLocalizedString("PrimaryLocationStart", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "")
    return String(format: format, from)
  }

  @objc(To:)
  public static func To(_ to: String) -> String {
    let format = NSLocalizedString("PrimaryLocationEnd", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "For trip titles, e.g., 'To work'")
    return String(format: format, to)
  }
  
}
