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
  
  
  // MARK: Attribution
  
  public static var DataProviders: String {
    return NSLocalizedString("Data Providers", tableName: "TripKit", bundle: .tripKit, comment: "Title for screen showing data providers")
  }
  
  public static func DataProvided(by provider: String) -> String {
    let format = NSLocalizedString("Data provided by %@", tableName: "TripKit", bundle: .tripKit, comment: "Text for attributing data sources. The list of providers will be used instead of '%@'")
    return String(format: format, provider)
  }
  
  public static var PoweredBy: String {
    return NSLocalizedString("Powered by", tableName: "TripKit", bundle: .tripKit, comment: "")
  }
  
  public static func PoweredBy(_ provider: String) -> String {
    let format = NSLocalizedString("Powered by %@", tableName: "TripKit", bundle: .tripKit, comment: "")
    return String(format: format, provider)
  }
  
  
  // MARK: - Routing

  @objc public static var PlanANewTrip: String {
    return NSLocalizedString("Plan a new trip", tableName: "TripKit", bundle: .tripKit, comment: "Title for button that allows users to plan a new trip")
  }
  
  public static var RequestSupport: String {
    return NSLocalizedString("Request support", tableName: "TripKit", bundle: .tripKit, comment: "Title for button that allows users to request support")
  }
  
  public static func RoutingFrom(_ start: String, toIsNotYetSupported end: String) -> String {
    let format = NSLocalizedString("Routing from %@ to %@ is not yet supported", tableName: "TripKit", bundle: .tripKit, comment: "Error message if interregional routing isn't yet supported")
    return String(format: format, start, end)
  }
  
  
  // MARK: -
  
  @objc public static var Now: String {
    return NSLocalizedString("Now", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Countdown cell 'now' indicator")
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
    return NSLocalizedString("Has reminder", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Accessibility annotation for trips which have a reminder set.")
  }
  
  @objc(ToArrival:)
  public static func To(arrival: String) -> String {
    let format = NSLocalizedString("to %@", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "to %date. (old key: DateToFormat)")
    return String(format: format, arrival)
  }
  
  @objc(DepartsAtTime:)
  public static func Departs(atTime time: String) -> String {
    let format = NSLocalizedString("departs %@", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Estimated time of departure; parameter is time, e.g., 'departs 15:30'")
    return String(format: format, time)
  }
  
  @objc(ArrivesAtTime:)
  public static func Arrives(atTime time: String) -> String {
    let format = NSLocalizedString("arrives %@", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Estimated time of arrival; parameter is time, e.g., 'arrives 15:30'")
    return String(format: format, time)
  }
  
  @objc public static var Checkmark: String {
    return NSLocalizedString("Checkmark", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Accessibility title for a checkmark/tick button")
  }
  
  public static func Showing(_ visible: Int, ofTransportModes all: Int) -> String {
    let format = NSLocalizedString("Showing %@ of %@ transport modes", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Indicator for how many transport modes are being displayed out of the total available ones for the region of the trip. First placeholder will be replaced with selected number, second with total number.")
    return String(format: format, NSNumber(value: visible), NSNumber(value: all))
  }
}
