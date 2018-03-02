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
    return NSLocalizedString("Alert", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Default title for alert view")
  }

  @objc
  public static var Back: String {
    return NSLocalizedString("Back", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Accessibility label for 'back' or 'previous' button")
  }
  
  @objc
  public static var Cancel: String {
    return NSLocalizedString("Cancel", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Cancel action")
  }
  
  @objc
  public static var OK: String {
    return NSLocalizedString("OK", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Ok action")
  }
  
  @objc
  public static var Close: String {
    return NSLocalizedString("Close", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Close action")
  }
  
  @objc
  public static var Later: String {
    return NSLocalizedString("Later", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Title of button to perform some action at a later time")
  }
  
  @objc
  public static var Confirm: String {
    return NSLocalizedString("Confirm", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Title on the button that asks users to confirm if they want to proceed with booking")
  }
  
  @objc
  public static var Delete: String {
    return NSLocalizedString("Delete", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Delete action")
  }
  
  @objc
  public static var Done: String {
    return NSLocalizedString("Done", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Done action")
  }
  
  @objc
  public static var Loading: String {
    return NSLocalizedString("Loading", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Title on the button that indicates to the user that booking is in progressing")
  }
  
  @objc
  public static var Next: String {
    return NSLocalizedString("Next", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Next action")
  }

  @objc
  public static var Retry: String {
    return NSLocalizedString("Retry", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Retry action, e.g., in case something didn't load")
  }
  
  @objc
  public static var Location: String {
    return NSLocalizedString("Location", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Title for unnamed location")
  }
  
  @objc
  public static var Name: String {
    return NSLocalizedString("Name", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Title for name of something (or someone)")
  }
  
  @objc
  public static var RealTime: String {
    return NSLocalizedString("Real-time", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Indicator for real-time information")
  }
  
  @objc
  public static var SearchForACity: String {
    return NSLocalizedString("Search for a city", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "")
  }
  
  @objc
  public static var WheelchairAccessible: String {
    return NSLocalizedString("Wheelchair accessible", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Indicator for wheelchair accessible services")
  }
  
  @objc
  public static var WheelchairNotAccessible: String {
    return NSLocalizedString("Not wheelchair accessible", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Indicator for wheelchair not accessible services")
  }

  @objc
  public static var WheelchairAccessibilityUnknown: String {
    return NSLocalizedString("Wheelchair accessibility unknown", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Indicator for unknow if service or station is wheelchair accessible or not")
  }

  @objc
  public static var ContactSupport: String {
    return NSLocalizedString("Contact support", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Title for button that allows users to contact our support team to help resolve some error in the app.")
  }
  
  @objc
  public static var Action: String {
    return NSLocalizedString("Action", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Accessibility label for action button")
  }
  
  @objc
  public static var ReadMore: String {
    return NSLocalizedString("Read more...", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "")
  }
  
  // MARK: - Reminders
  
  @objc
  public static var ForWhenToLeave: String {
    return NSLocalizedString("For when to leave", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Reminder to leave preference")
  }
  
  @objc
  public static var MinutesBeforeTrip: String {
    return NSLocalizedString("Minutes before trip", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Reminder to leave preference")
  }
  
  @objc
  public static var Reminder: String {
    return NSLocalizedString("Reminder", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Action title to add/remove reminder")
  }
  
  
  // MARK: - Feedback
  
  @objc
  public static var Never: String {
    return NSLocalizedString("Never", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Response to question whether user wants to report a problem when taking a screenshot. Also used in context of repetitions (especially recurring events).")
  }
  
  @objc
  public static var ReportProblem: String {
    return NSLocalizedString("Report Problem", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Button title to report a problem")
  }
  
  @objc
  public static var WouldYouLikeToReportAProblem: String {
    return NSLocalizedString("Would you like to report a problem?", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Question asked when user is taking a screenshot")
  }
  
  // MARK: - Current location
  
  @objc
  public static var CurrentLocation: String {
    return NSLocalizedString("Current Location", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Title for user's current location")
  }
  
  @objc
  public static var ChangeTrackingOptions: String {
    return NSLocalizedString("Change tracking options", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Accessibility - user location button - hint")
  }
  
  @objc
  public static var TrackingOff: String {
    return NSLocalizedString("Tracking - off", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Accessibility - user location button - off")
  }
  
  @objc
  public static var TrackingOn: String {
    return NSLocalizedString("Tracking - on", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "user location button - follow")
  }
  
  @objc
  public static var TrackingOnWithHeading: String {
    return NSLocalizedString("Tracking - on with heading", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "user location button - follow with heading")
  }
  
  @objc
  public static var TapToSetLocation: String {
    return NSLocalizedString("Tap to set location", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Tap to set location. (old key: SetLocation)")
  }
  
  @objc
  public static var PleaseVerifyTheLocation: String {
    return NSLocalizedString("Please verify the location", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Please verify the location prompt")
  }
  
  @objc
  public static var PleaseSelectALocation: String {
    return NSLocalizedString("Please select a location", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Please select a location prompt")
  }
  
  @objc
  public static var Search: String {
    return NSLocalizedString("Search", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Empty search bar placeholder")
  }
  
  @objc
  public static var Score: String {
    return NSLocalizedString("Score", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Sort by overall score, like a ranking.")
  }
  
  @objc
  public static var Distance: String {
    return NSLocalizedString("Distance", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Sort by distance")
  }
  
  @objc
  public static var SearchResults: String {
    return NSLocalizedString("Search Results", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "")
  }
  
  
  // MARK: - Format
  
  @objc(Recurrences:)
  public static func Recurrences(_ count: Int) -> String {
    let format = NSLocalizedString("%lu recurrences", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Number of repeats. (old key: NumberRecurrences)")
    return String(format: format, count)
  }

  @objc(FromDate:)
  public static func From(date: String) -> String {
    let format = NSLocalizedString("Starting %@", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Starting %date. (old key: DateFromFormat)")
    return String(format: format, date)
  }
  
  @objc(ToDate:)
  public static func To(date: String) -> String {
    let format = NSLocalizedString("Up to %@", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Up to %date. (old key: DateToFormat)")
    return String(format: format, date)
  }
  
  @objc(Every:)
  public static func Every(dayString: String) -> String {
    let format = NSLocalizedString("Every %@", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "'Every %day' in context of repetitions (especially recurring events), e.g., 'Every Monday'. (old key: EveryDayFormat)")
    return String(format: format, dayString)
  }
  
  @objc(SearchingFor:)
  public static func SearchingFor(_ keyword: String) -> String {
    let format = NSLocalizedString("Searching for '%@'...", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Placeholder text while waiting for server response when searching for a location.")
    return String(format: format, keyword)
  }
  
}
