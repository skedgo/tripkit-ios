//
//  Loc+TripKitInterApp.swift
//  TripKit-iOS
//
//  Created by Adrian Schönig on 23.02.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

extension Loc {

  @objc public static var OpenInDotDotDot: String {
    return NSLocalizedString("Open in…", tableName: "TripKit", bundle: .tripKit, comment: "Action button title for opening something in another app. Tapping this button will show a list of app names.")
  }

  @objc public static var GetDirections: String {
    return NSLocalizedString("Get directions", tableName: "TripKit", bundle: .tripKit, comment: "Action button title for getting turn-by-turn directions")
  }
  
  @objc public static var AppleMaps: String {
    return NSLocalizedString("Apple Maps", tableName: "TripKit", bundle: .tripKit, comment: "apple maps directions action")
  }
  
  @objc public static var GoogleMaps: String {
    return NSLocalizedString("Google Maps", tableName: "TripKit", bundle: .tripKit, comment: "google maps directions action")
  }
  
  @objc public static var Call: String {
    return NSLocalizedString("Call", tableName: "TripKit", bundle: .tripKit, comment: "")
  }
  
  @objc public static var SendSMS: String {
    return NSLocalizedString("Send SMS", tableName: "TripKit", bundle: .tripKit, comment: "Send SMS action button")
  }
  
  @objc public static var ShowWebsite: String {
    return NSLocalizedString("Show website", tableName: "TripKit", bundle: .tripKit, comment: "Show website action button")
  }

  public static var Book: String {
    return NSLocalizedString("Book", tableName: "TripKit", bundle: .tripKit, comment: "Action title to make a booking")
  }
  
  @objc(BookWithService:)
  public static func BookWith(service: String) -> String {
    let format = NSLocalizedString("Book with %@", tableName: "TripKit", bundle: .tripKit, comment: "Action title to make a booking using service/app named '@%'")
      return String(format: format, service)
  }
  
  public static var ExtendBooking: String {
    return NSLocalizedString("Extend", tableName: "TripKit", bundle: .tripKit, comment: "Action title to extend an existing booking")
  }
  
  @objc(CallService:)
  public static func Call(service: String) -> String {
    let format = NSLocalizedString("Call %@", tableName: "TripKit", bundle: .tripKit, comment: "Action title to make a call to service/company named '@%'")
      return String(format: format, service)
  }
  
  @objc(GetAppNamed:)
  public static func Get(appName: String) -> String {
    let format = NSLocalizedString("Get %@", tableName: "TripKit", bundle: .tripKit, comment: "Action title get/download app of name '@%'")
      return String(format: format, appName)
  }

  public static var GetApp: String {
    return NSLocalizedString("Get app", tableName: "TripKit", bundle: .tripKit, comment: "Title for button to get/download an external app.")
  }

  public static func ConfirmOpen(appName: String) -> String {
    let format = NSLocalizedString("Please confirm switching to %@ to get directions.", tableName: "TripKit", bundle: .tripKit, comment: "Confirmation text to open app of name '@%'")
    return String(format: format, appName)
  }

  public static func Open(appName: String) -> String {
    let format = NSLocalizedString("Open %@", tableName: "TripKit", bundle: .tripKit, comment: "Action title open app of name '@%'")
    return String(format: format, appName)
  }
  
  public static var OpenApp: String {
    return NSLocalizedString("Open app", tableName: "TripKit", bundle: .tripKit, comment: "Title for button that opens an external app.")
  }
  
  public static var Unlock: String {
    return NSLocalizedString("Unlock", tableName: "TripKit", bundle: .tripKit, comment: "Title for button that unlocks a shared vehicle.")
  }
}

