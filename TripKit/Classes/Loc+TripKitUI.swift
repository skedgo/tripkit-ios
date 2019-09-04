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
    return NSLocalizedString("Loading…", tableName: "TripKit", bundle: .tripKit, comment: "Indicating when something is loading")
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
  
  public static var Expand: String {
    return NSLocalizedString("Expand", tableName: "TripKit", bundle: .tripKit, comment: "Accessibility title for button that points down to expand a section")
  }

  public static var Collapse: String {
    return NSLocalizedString("Collapse", tableName: "TripKit", bundle: .tripKit, comment: "Accessibility title for button that points up to collapse a section")
  }

  // MARK: - Attribution
  
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

  public static var PlanTrip: String {
    return NSLocalizedString("Plan Trip", tableName: "TripKit", bundle: .tripKit, comment: "Title of page to plan a trip")
  }
  
  @objc public static var PlanANewTrip: String {
    return NSLocalizedString("Plan a new trip", tableName: "TripKit", bundle: .tripKit, comment: "Title for button that allows users to plan a new trip")
  }
  
  @objc public static var Trips: String {
    return NSLocalizedString("Trips", tableName: "TripKit", bundle: .tripKit, comment: "Title of page that shows routing results")
  }
  
  public static var StartLocation: String {
    return NSLocalizedString("Start location", tableName: "TripKit", bundle: .tripKit, comment: "Placeholder name for origin (then replaced with address or name)")
  }

  public static var EndLocation: String {
    return NSLocalizedString("End location", tableName: "TripKit", bundle: .tripKit, comment: "Placeholder name for destination (then replaced with address or name)")
  }

  public static var RequestSupport: String {
    return NSLocalizedString("Request support", tableName: "TripKit", bundle: .tripKit, comment: "Title for button that allows users to request support")
  }
  
  public static func RoutingFrom(_ start: String, toIsNotYetSupported end: String) -> String {
    let format = NSLocalizedString("Routing from %@ to %@ is not yet supported", tableName: "TripKit", bundle: .tripKit, comment: "Error message if interregional routing isn't yet supported")
    return String(format: format, start, end)
  }
  
  public static var NoRoutesFound: String {
    return NSLocalizedString("No routes found.", tableName: "TripKit", bundle: .tripKit, comment: "Error title when routing produced no results (but no specific error was returned from routing).")
  }
  
  public static var PleaseAdjustYourQuery: String {
    return NSLocalizedString("Please adjust your query and try again.", tableName: "TripKit", bundle: .tripKit, comment: "Error recovery suggestion for when routing produced no results (but no specific error was returned from routing).")
  }

  public static var BadgeEasiest: String {
    return NSLocalizedString("Easiest", tableName: "TripKit", bundle: .tripKit, comment: "Trip badge: Easiest")
  }

  public static var BadgeGreenest: String {
    return NSLocalizedString("Greenest", tableName: "TripKit", bundle: .tripKit, comment: "Trip badge: Greenest")
  }

  public static var BadgeFastest: String {
    return NSLocalizedString("Fastest", tableName: "TripKit", bundle: .tripKit, comment: "Trip badge: Fastest")
  }

  public static var BadgeHealthiest: String {
    return NSLocalizedString("Healthiest", tableName: "TripKit", bundle: .tripKit, comment: "Trip badge: Healthiest")
  }

  public static var BadgeCheapest: String {
    return NSLocalizedString("Cheapest", tableName: "TripKit", bundle: .tripKit, comment: "Trip badge: Cheapest")
  }

  public static var BadgeRecommended: String {
    return NSLocalizedString("Recommended", tableName: "TripKit", bundle: .tripKit, comment: "Trip badge: Recommended")
  }

  
  // MARK: - Trip details

  public static func Trip(index: Int?) -> String {
    guard let index = index else { return Loc.Trip }
    let format = NSLocalizedString("Trip %@", tableName: "TripKit", bundle: .tripKit, comment: "Title for trip of provided index")
    return String(format: format, NSNumber(value: index))
  }
  
  public static var ActionStart: String {
    return NSLocalizedString("Start", tableName: "TripKit", bundle: .tripKit, comment: "Title of button to start a trip")
  }

  public static func GetOnService(To location: String) -> String {
    let format = NSLocalizedString("Get on service to %@", tableName: "TripKit", bundle: .tripKit, comment: "Instruction to get a service towards provided destination")
    return String(format: format, location)
  }

  public static func AlongStreet(named: String?) -> String {
    if let name = named {
      let format = NSLocalizedString("Along %@", tableName: "TripKit", bundle: .tripKit, comment: "Instruction to follow street of the provided name")
      return String(format: format, name)
    } else {
      return NSLocalizedString("Along unnamed street", tableName: "TripKit", bundle: .tripKit, comment: "Instruction to follow unnamed street")
    }
  }

  
  // MARK: - Departures + Services

  @objc public static var Timetable: String {
    return NSLocalizedString("Timetable", tableName: "TripKit", bundle: .tripKit, comment: "Title of button to access timetable")
  }
  
  public static func Every(prefix: String? = nil, repetition: String) -> String {
    if let prefix = prefix {
      let format = NSLocalizedString("%@ every %@", tableName: "TripKit", bundle: .tripKit, comment: "Filler for a specific frequency-based service indicating its frequency, e.g., 'M10 every 10 minutes'")
      return String(format: format, prefix, repetition)
    } else {
      let format = NSLocalizedString("Every %@", tableName: "TripKit", bundle: .tripKit, comment: "Filler for a frequency-based service indicating its frequency, e.g., 'Every 10 minutes'")
      return String(format: format, repetition)
    }
  }
  
  public static func At(what: String, time: String) -> String {
    let format = NSLocalizedString("%@ at %@", tableName: "TripKit", bundle: .tripKit, comment: "Filler for a specific service running at a time, e.g., '396 at 11:56am'")
    return String(format: format, what, time)
  }
  
  public static func At(time: String) -> String {
    let format = NSLocalizedString("At %@", tableName: "TripKit", bundle: .tripKit, comment: "Filler for a service running at time, e.g., 'At 11:56am'")
    return String(format: format, time)
  }

  public static func More(count: Int) -> String? {
    guard count > 0 else { return nil }
    let format = NSLocalizedString("%@ more", tableName: "TripKit", bundle: .tripKit, comment: "Text for an 'x more' indication if there's more content. '%@' will be replaced with a number")
    return String(format: format, NSNumber(value: count))
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
  
  public static func Departs(atTime time: String, capitalize: Bool = false) -> String {
    let format = NSLocalizedString("departs %@", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Estimated time of departure; parameter is time, e.g., 'departs 15:30'")
    return String(format: capitalize ? format.localizedCapitalized : format, time)
  }
  
  public static func Arrives(atTime time: String, capitalize: Bool = false) -> String {
    let format = NSLocalizedString("arrives %@", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Estimated time of arrival; parameter is time, e.g., 'arrives 15:30'")
    return String(format: capitalize ? format.localizedCapitalized : format, time)
  }
  
  @objc public static var Checkmark: String {
    return NSLocalizedString("Checkmark", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Accessibility title for a checkmark/tick button")
  }
  
  public static func Showing(_ visible: Int, ofTransportModes all: Int) -> String {
    let format = NSLocalizedString("Showing %@ of %@ transport modes", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Indicator for how many transport modes are being displayed out of the total available ones for the region of the trip. First placeholder will be replaced with selected number, second with total number.")
    return String(format: format, NSNumber(value: visible), NSNumber(value: all))
  }
  
  // MARK: - Autocompletion
  
  @objc
  public static var InstantResults: String {
    return NSLocalizedString("Instant results", tableName: "TripKit", bundle: .tripKit, comment: "Title for section with instant results in autocompletion")
  }

  @objc
  public static var MoreResults: String {
    return NSLocalizedString("More results", tableName: "TripKit", bundle: .tripKit, comment: "'More results' section in autocompletion")
  }

}
