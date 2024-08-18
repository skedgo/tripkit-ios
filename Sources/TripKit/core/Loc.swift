//
//  Loc.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/11/16.
//
//

import Foundation

public class Loc : NSObject {
  
  fileprivate override init() { super.init() }

  @objc
  public static var Alert: String {
    return NSLocalizedString("Alert", tableName: "Shared", bundle: .tripKit, comment: "Default title for alert view")
  }

  @objc
  public static var Back: String {
    return NSLocalizedString("Back", tableName: "Shared", bundle: .tripKit, comment: "Accessibility label for 'back' or 'previous' button")
  }
  
  @objc
  public static var Cancel: String {
    return NSLocalizedString("Cancel", tableName: "Shared", bundle: .tripKit, comment: "Cancel action")
  }
  
  @objc
  public static var OK: String {
    return NSLocalizedString("OK", tableName: "Shared", bundle: .tripKit, comment: "OK action")
  }
  
  @objc
  public static var Close: String {
    return NSLocalizedString("Close", tableName: "Shared", bundle: .tripKit, comment: "Close action")
  }
  
  @objc
  public static var Later: String {
    return NSLocalizedString("Later", tableName: "Shared", bundle: .tripKit, comment: "Title of button to perform some action at a later time")
  }
  
  @objc
  public static var Confirm: String {
    return NSLocalizedString("Confirm", tableName: "Shared", bundle: .tripKit, comment: "Title on the button that asks users to confirm if they want to proceed with booking")
  }
  
  @objc
  public static var Delete: String {
    return NSLocalizedString("Delete", tableName: "Shared", bundle: .tripKit, comment: "Delete action")
  }
  
  @objc
  public static var Done: String {
    return NSLocalizedString("Done", tableName: "Shared", bundle: .tripKit, comment: "Done action")
  }
  
  @objc
  public static var Select: String {
    return NSLocalizedString("Select", tableName: "Shared", bundle: .tripKit, comment: "Select action")
  }
  
  @objc
  public static var Next: String {
    return NSLocalizedString("Next", tableName: "Shared", bundle: .tripKit, comment: "Next action")
  }

  @objc
  public static var Retry: String {
    return NSLocalizedString("Retry", tableName: "Shared", bundle: .tripKit, comment: "Retry action, e.g., in case something didn't load")
  }
  
  @objc
  public static var Location: String {
    return NSLocalizedString("Location", tableName: "Shared", bundle: .tripKit, comment: "Title for unnamed location")
  }
  
  @objc
  public static var Name: String {
    return NSLocalizedString("Name", tableName: "Shared", bundle: .tripKit, comment: "Title for name of something (or someone)")
  }
  
  public static var RealTime: String {
    return NSLocalizedString("Real-time", tableName: "Shared", bundle: .tripKit, comment: "Indicator for real-time information")
  }
  
  public static var LiveTraffic: String {
    return NSLocalizedString("Live traffic", tableName: "Shared", bundle: .tripKit, comment: "Indicator for real-time information")
  }
  
  public static var WheelchairAccessible: String {
    return NSLocalizedString("Wheelchair accessible", tableName: "Shared", bundle: .tripKit, comment: "Indicator for wheelchair accessible services")
  }
  
  public static var WheelchairNotAccessible: String {
    return NSLocalizedString("Not wheelchair accessible", tableName: "Shared", bundle: .tripKit, comment: "Indicator for wheelchair not accessible services")
  }

  public static var WheelchairAccessibilityUnknown: String {
    return NSLocalizedString("Wheelchair accessibility unknown", tableName: "Shared", bundle: .tripKit, comment: "Indicator for unknow if service or station is wheelchair accessible or not")
  }

  public static var BicycleAccessible: String {
    return NSLocalizedString("Bicycle accessible", tableName: "Shared", bundle: .tripKit, comment: "Indicator for bicycle accessible services")
  }
  
  public static var ContactSupport: String {
    return NSLocalizedString("Contact support", tableName: "Shared", bundle: .tripKit, comment: "Title for button that allows users to contact our support team to help resolve some error in the app.")
  }
  
  public static var AllDay: String {
    return NSLocalizedString("all-day", tableName: "Shared", bundle: .tripKit, comment: "Indicator that an event is all-day, or that something is open all-day")
  }

  public static var Scheduled: String {
    return NSLocalizedString("Scheduled", tableName: "TripKit", bundle: .tripKit, comment: "Label to indicate that the time for a service is the scheduled time, i.e., displayed as on the timetable with no real-time data available.")
  }

  public static var Cancelled: String {
    return NSLocalizedString("Cancelled", tableName: "Shared", bundle: .tripKit, comment: "Label for when a service is cancelled.")
  }

  public static var NoRealTimeAvailable: String {
    return NSLocalizedString("No real-time available", tableName: "TripKit", bundle: .tripKit, comment: "Indicator to show when a service does not have real-time data (even though we usually get it for services like this.)")
  }

  public static var OnTime: String {
    return NSLocalizedString("On time", tableName: "TripKit", bundle: .tripKit, comment: "Indicator to show when a service is on time according to real-time data.")
  }
  
  public static var DateTimeSelectionBelow: String {
    return NSLocalizedString("Below earliest date", tableName: "TripKit", bundle: .tripKit, comment: "Indicator to show if the selected datetime is below the minimum datetime.")
  }
  
  public static var DateTimeSelectionAbove: String {
    return NSLocalizedString("Beyond furthest date", tableName: "TripKit", bundle: .tripKit, comment: "Indicator to show if the selected datetime is above the maximum datetime.")
  }
  
  public static func LateService(minutes: Int, service: String?) -> String {
    if let service = service {
      let format = NSLocalizedString("%1$@ late (%2$@ service)", tableName: "TripKit", bundle: .tripKit, comment: "Format for a service's real-time indicator for a service which is late, e.g., '1 min late (1:10 pm service). This means #1 is replaced with something like '1 min' and #2 is replaced with the original time, e.g., '1:10 pm').")
      return String(format: format, minuteToString(minutes), service)
    } else {
      let format = NSLocalizedString("%1$@ late", tableName: "TripKit", bundle: .tripKit, comment: "Format for a service's real-time indicator for a service which is late, e.g., '1 min late. This means #1 is replaced with something like '1 min'.")
      return String(format: format, minuteToString(minutes))
    }
  }
  
  public static func EarlyService(minutes: Int, service: String?) -> String {
    if let service = service {
      let format = NSLocalizedString("%1$@ early (%2$@ service)", tableName: "TripKit", bundle: .tripKit, comment: "Format for a service's real-time indicator for a service which is early, e.g., '1 min early (1:10 pm service). This means #1 is replaced with something like '1 min' and #2 is replaced with the original time, e.g., '1:10 pm').")
      return String(format: format, minuteToString(minutes), service)
    } else {
      let format = NSLocalizedString("%1$@ early", tableName: "TripKit", bundle: .tripKit, comment: "Format for a service's real-time indicator for a service which is early, e.g., '1 min early. This means #1 is replaced with something like '1 min'.")
      return String(format: format, minuteToString(minutes))
    }
  }
  
  private static func minuteToString(_ minutes: Int) -> String {
    var component = DateComponents()
    component.calendar = .autoupdatingCurrent
    component.timeZone = .autoupdatingCurrent
    component.minute = minutes
    return DateComponentsFormatter.localizedString(from: component, unitsStyle: .short)!
  }

  // MARK: - Reminders
  
  @objc
  public static var ForWhenToLeave: String {
    return NSLocalizedString("For when to leave", tableName: "Shared", bundle: .tripKit, comment: "Reminder to leave preference")
  }
  
  @objc
  public static var MinutesBeforeTrip: String {
    return NSLocalizedString("Minutes before trip", tableName: "Shared", bundle: .tripKit, comment: "Reminder to leave preference")
  }
  
  @objc
  public static var Reminder: String {
    return NSLocalizedString("Reminder", tableName: "Shared", bundle: .tripKit, comment: "Action title to add/remove reminder")
  }
  
  
  // MARK: - Feedback
  
  @objc
  public static var Never: String {
    return NSLocalizedString("Never", tableName: "Shared", bundle: .tripKit, comment: "Response to question whether user wants to report a problem when taking a screenshot. Also used in context of repetitions (especially recurring events).")
  }
  
  @objc
  public static var ReportProblem: String {
    return NSLocalizedString("Report Problem", tableName: "Shared", bundle: .tripKit, comment: "Button title to report a problem")
  }
  
  @objc
  public static var WouldYouLikeToReportAProblem: String {
    return NSLocalizedString("Would you like to report a problem?", tableName: "Shared", bundle: .tripKit, comment: "Question asked when user is taking a screenshot")
  }
  
  // MARK: - Current location
  
  @objc
  public static var CurrentLocation: String {
    return NSLocalizedString("Current Location", tableName: "Shared", bundle: .tripKit, comment: "Title for user's current location")
  }

  @objc
  public static var CouldNotFetchCurrentLocationTitle: String {
    return NSLocalizedString("Could not determine your current location.", tableName: "Shared", bundle: .tripKit, comment: "Error title when GPS failed.")
  }

  @objc
  public static var CouldNotFetchCurrentLocationRecovery: String {
    return NSLocalizedString("Please try again or set your location manually.", tableName: "Shared", bundle: .tripKit, comment: "Error recovery suggestion when GPS fails.")
  }

  @objc
  public static var TapToSetLocation: String {
    return NSLocalizedString("Tap to set location", tableName: "Shared", bundle: .tripKit, comment: "Tap to set location. (old key: SetLocation)")
  }
  
  @objc
  public static var PleaseVerifyTheLocation: String {
    return NSLocalizedString("Please verify the location", tableName: "Shared", bundle: .tripKit, comment: "Please verify the location prompt")
  }
  
  @objc
  public static var PleaseSelectALocation: String {
    return NSLocalizedString("Please select a location", tableName: "Shared", bundle: .tripKit, comment: "Please select a location prompt")
  }
  
  @objc
  public static var Search: String {
    return NSLocalizedString("Search", tableName: "Shared", bundle: .tripKit, comment: "Empty search bar placeholder")
  }
  
  @objc
  public static var Score: String {
    return NSLocalizedString("Score", tableName: "Shared", bundle: .tripKit, comment: "Sort by overall score, like a ranking.")
  }
  
  @objc
  public static var Distance: String {
    return NSLocalizedString("Distance", tableName: "Shared", bundle: .tripKit, comment: "Sort by distance")
  }
  
  @objc
  public static var SearchResults: String {
    return NSLocalizedString("Search Results", tableName: "Shared", bundle: .tripKit, comment: "")
  }
  
  public static var LocalizationPermissionsMissing: String {
    return NSLocalizedString("Location services are required to use this feature. Please go to the Settings app > Privacy > Location Services, make sure they are turned on and authorise this app.", tableName: "Shared", bundle: .tripKit, comment: "Location iOS authorisation needed text")
  }
  
  
  // MARK: - Format
  
  @objc(Recurrences:)
  public static func Recurrences(_ count: Int) -> String {
    let format = NSLocalizedString("%lu recurrences", tableName: "Shared", bundle: .tripKit, comment: "Number of repeats. (old key: NumberRecurrences)")
    return String(format: format, count)
  }

  @objc(FromDate:)
  public static func From(date: String) -> String {
    let format = NSLocalizedString("Starting %@", tableName: "Shared", bundle: .tripKit, comment: "Starting %date. (old key: DateFromFormat)")
    return String(format: format, date)
  }
  
  @objc(ToDate:)
  public static func To(date: String) -> String {
    let format = NSLocalizedString("Up to %@", tableName: "Shared", bundle: .tripKit, comment: "Up to %date. (old key: DateToFormat)")
    return String(format: format, date)
  }
  
  public static func LastUpdated(date: String) -> String {
    let format = NSLocalizedString("Last updated: %@", tableName: "Shared", bundle: .tripKit, comment: "Last updated at %date")
    return String.init(format: format, date)
  }
  
  @objc(Every:)
  public static func Every(dayString: String) -> String {
    let format = NSLocalizedString("Every %@", tableName: "Shared", bundle: .tripKit, comment: "'Every %day' in context of repetitions (especially recurring events), e.g., 'Every Monday'. (old key: EveryDayFormat)")
    return String(format: format, dayString)
  }
  
  @objc(SearchingFor:)
  public static func SearchingFor(_ keyword: String) -> String {
    let format = NSLocalizedString("Searching for '%@'…", tableName: "Shared", bundle: .tripKit, comment: "Placeholder text while waiting for server response when searching for a location.")
    return String(format: format, keyword)
  }
  
  public static func PercentCycleFriendly(_ percentage: String) -> String {
    let format = NSLocalizedString("%@ cycle friendly", tableName: "TripKit", bundle: .tripKit, comment: "Indicator for how cycle-friendly a cycling route is. Placeholder will get replaced with '75%'.")
    return String(format: format, percentage)
  }

  public static func PercentWheelchairFriendly(_ percentage: String) -> String {
    let format = NSLocalizedString("%@ wheelchair friendly", tableName: "TripKit", bundle: .tripKit, comment: "Indicator for how wheelchair-friendly a wheelchair route is. Placeholder will get replaced with '75%'.")
    return String(format: format, percentage)
  }
  
  public static func MoreLocationInfo(_ address: String) -> String {
    let format = NSLocalizedString("More information about %@", tableName: "Shared", bundle: .tripKit, comment: "Accessibility label for the information button next to addresses in an autocomplete item.")
    return String(format: format, address)
  }

  public static var TapToLearnLocationInfo: String {
    return NSLocalizedString("Tap to learn more about this location.", tableName: "Shared", bundle: .tripKit, comment: "Accessibility hint for info button which provides additional information.")
  }
  
  public static var TapToSelectAddress: String {
    return NSLocalizedString("Tap to select this address as origin or destination.", tableName: "Shared", bundle: .tripKit, comment: "Accessibility hint for an autocomplete item to provide selection capability.")
  }
  
  public static var TapToSelectCurrentLocation: String {
    return NSLocalizedString("Tap to select your current location as the destination or origin.", tableName: "Shared", bundle: .tripKit, comment: "Accessibility hint for an current location item to provide selection capability.")
  }
  
  public static var SelectTime: String {
    return NSLocalizedString("Select Time", tableName: "Shared", bundle: .tripKit, comment: "Title for Date Time selection.")
  }
  
}
