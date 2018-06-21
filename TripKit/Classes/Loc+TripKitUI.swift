//
//  Loc+TripKitUI.swift
//  TripKit-iOS
//
//  Created by Adrian Schönig on 23.02.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

extension Loc {
  
  public static var PlanATripAndItllShowUpHere: String {
    return NSLocalizedString("Plan a trip and it will show up here.", tableName: "TripKit", bundle: .tripKit, comment: "")
  }
  
  public static var LoadingDotDotDot: String {
    return NSLocalizedString("Loading...", tableName: "TripKit", bundle: .tripKit, comment: "Indicating when something is loading")
  }
  
  public static var BusyGettingYourTrip: String {
    return NSLocalizedString("We are busy getting your upcoming trip. Please wait...", tableName: "TripKit", bundle: .tripKit, comment: "")
  }
  
  public static var LeaveIn: String {
    return NSLocalizedString("Leave in", tableName: "TripKit", bundle: .tripKit, comment: "Title for when to depart. Countdown to departure will be displayed below.")
  }
  
  public static var ArriveIn: String {
    return NSLocalizedString("Arrive in", tableName: "TripKit", bundle: .tripKit, comment: "Title for when you'll arrive when on a trip. Countdown to arrival will be displayed below.")
  }
  
  // MARK: -
  
  @objc public static var Now: String {
    return NSLocalizedString("Now", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Countdown cell 'now' indicator")
  }
  
  @objc(InDurationString:)
  public static func In(duration: String) -> String {
    let format = NSLocalizedString("In %@", tableName: "TripKit", bundle: .tripKit, comment: "Title for something to happen in a certain timeframe, e.g., 'In 5 mins'")
    return String(format: format, duration)
  }
  
  @objc(AgoDurationString:)
  public static func Ago(duration: String) -> String {
    let format = NSLocalizedString("%@ ago", tableName: "TripKit", bundle: .tripKit, comment: "Title for something that happened a certain timeframe ago, e.g., '5 mins ago'")
    return String(format: format, duration)
  }
  
  
  @objc public static var HasReminder: String {
    return NSLocalizedString("Has reminder", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Accessibility annotation for trips which have a reminder set.")
  }
  
  @objc(ToArrival:)
  public static func To(arrival: String) -> String {
    let format = NSLocalizedString("to %@", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "to %date. (old key: DateToFormat)")
    return String(format: format, arrival)
  }
  
  @objc(DepartsAtTime:)
  public static func Departs(atTime time: String) -> String {
    let format = NSLocalizedString("departs %@", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Estimated time of departure; parameter is time, e.g., 'departs 15:30'")
    return String(format: format, time)
  }
  
  @objc(ArrivesAtTime:)
  public static func Arrives(atTime time: String) -> String {
    let format = NSLocalizedString("arrives %@", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Estimated time of arrival; parameter is time, e.g., 'arrives 15:30'")
    return String(format: format, time)
  }
  
  @objc public static var Checkmark: String {
    return NSLocalizedString("Checkmark", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Accessibility title for a checkmark/tick button")
  }
  
  public static func Showing(_ visible: Int, ofTransportModes all: Int) -> String {
    let format = NSLocalizedString("Showing %@ of %@ transport modes", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Indicator for how many transport modes are being displayed out of the total available ones for the region of the trip. First placeholder will be replaced with selected number, second with total number.")
    return String(format: format, NSNumber(value: visible), NSNumber(value: all))
  }
}
