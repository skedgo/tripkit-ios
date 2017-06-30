//
//  Loc.swift
//  Pods
//
//  Created by Adrian Schoenig on 30/11/16.
//
//

import Foundation

public class Loc : NSObject {
  
  fileprivate override init() { super.init() }
  
  public static var Cancel: String {
    return NSLocalizedString("Cancel", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Cancel action")
  }
  
  public static var OK: String {
    return NSLocalizedString("OK", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Ok action")
  }
  
  public static var Close: String {
    return NSLocalizedString("Close", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Close action")
  }
  
  public static var Confirm: String {
    return NSLocalizedString("Confirm", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Title on the button that asks users to confirm if they want to proceed with booking")
  }
  
  public static var Delete: String {
    return NSLocalizedString("Delete", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Delete action")
  }
  
  public static var Done: String {
    return NSLocalizedString("Done", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Done action")
  }
  
  public static var Loading: String {
    return NSLocalizedString("Loading", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Title on the button that indicates to the user that booking is in progressing")
  }
  
  public static var Next: String {
    return NSLocalizedString("Next", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Next action")
  }

  public static var Retry: String {
    return NSLocalizedString("Retry", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Retry action, e.g., in case something didn't load")
  }
  
  public static var CurrentLocation: String {
    return NSLocalizedString("Current Location", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Title for user's current location")
  }
  
  public static var Location: String {
    return NSLocalizedString("Location", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Title for unnamed location")
  }
  
  public static var Name: String {
    return NSLocalizedString("Name", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Title for name of something (or someone)")
  }
  
  public static var RealTime: String {
    return NSLocalizedString("Real-time", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Indicator for real-time information")
  }
  
  public static var SearchForACity: String {
    return NSLocalizedString("Search for a city", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "")
  }
  
  public static var WheelchairAccessible: String {
    return NSLocalizedString("Wheelchair accessible", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Indicator for wheelchair accessible services")
  }
  
  public static var ContactSupport: String {
    return NSLocalizedString("Contact support", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Title for button that allows users to contact our support team to help resolve some error in the app.")
  }
  
  // MARK: - Reminders
  
  public static var ForWhenToLeave: String {
    return NSLocalizedString("For when to leave", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Reminder to leave preference")
  }
  
  public static var MinutesBeforeTrip: String {
    return NSLocalizedString("Minutes before trip", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Reminder to leave preference")
  }
  
  public static var Reminder: String {
    return NSLocalizedString("Reminder", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Action title to add/remove reminder")
  }
  
  
  // MARK: - Feedback
  
  public static var Never: String {
    return NSLocalizedString("Never", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Response to question whether user wants to report a problem when taking a screenshot. Also used in context of repetitions (especially recurring events).")
  }
  
  public static var ReportProblem: String {
    return NSLocalizedString("Report Problem", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Button title to report a problem")
  }
  
  public static var WouldYouLikeToReportAProblem: String {
    return NSLocalizedString("Would you like to report a problem?", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Question asked when user is taking a screenshot")
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
  
  
}
