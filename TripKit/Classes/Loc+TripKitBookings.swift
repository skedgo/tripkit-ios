//
//  Loc+TripKitBookings.swift
//  TripKit-iOS
//
//  Created by Adrian Schönig on 23.02.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

// MARK: - Accounts

extension Loc {
  
  @objc public static var AlreadyHaveAnAccount: String {
    return NSLocalizedString("Already have an account? Sign in", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Option for users if they already owned a SkedGo account")
  }

  @objc public static var DontHaveAnAccount: String {
    return NSLocalizedString("Don't have an account? Sign up", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Option for users if they don't yet have a SkedGo account")
  }

  @objc public static var Authentication: String {
    return NSLocalizedString("Authentication", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Source where the account was derived, e.g., Facebook")
  }

  @objc public static var SignOut: String {
    return NSLocalizedString("Sign out", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Instruction for signing out user account")
  }

  @objc public static var Mail: String {
    return NSLocalizedString("Email", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "For email address")
  }

  @objc public static var Password: String {
    return NSLocalizedString("Password", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "")
  }

  
  @objc public static var Change: String {
    return NSLocalizedString("Change", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Instruction for changing password")
  }

  @objc public static var AppWillNowSignOut: String {
    return NSLocalizedString("The app will now sign out", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Message that indicates the app is about to sign users out of their user accounts")
  }

  @objc public static var InvalidAccount: String {
    return NSLocalizedString("Invalid account", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Title for alert that indicates the user account has become invalid")
  }
  
  @objc public static var SigningOut: String {
    return NSLocalizedString("Signing out", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Message that indicates the app is signing users out of their accounts")
  }
  
  @objc public static var MyAccount: String {
    return NSLocalizedString("My account", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Title for view that shows the summary of a user's account information")
  }
  
  @objc public static var SignIn: String {
    return NSLocalizedString("Sign in", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Title of page or button to sign in")
  }
  
  @objc public static var SigningIn: String {
    return NSLocalizedString("Signing in", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Message that indicates the app is signing users into their user accounts")
  }
  
  @objc public static var SignUp: String {
    return NSLocalizedString("Sign up", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Title of page or button to sign up")
  }
  
  @objc public static var NewAccount: String {
    return NSLocalizedString("New account", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Title of page to create new account")
  }
  
  @objc public static var CreatingAccount: String {
    return NSLocalizedString("Creating account", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Message that indicates the app is creating accounts for users")
  }
  
  @objc public static var CannotProceedWithoutMail: String {
    return NSLocalizedString("Cannot proceed without a valid email address", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "")
  }
  
  @objc public static var CannotProceedWithoutPassword: String {
    return NSLocalizedString("Sign up cannot be completed without a valid password", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "")
  }
  
  @objc public static var UnknownError: String {
    return NSLocalizedString("Unknown error", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "")
  }
  
  @objc public static var OpenSettings: String {
    return NSLocalizedString("Open Settings", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Button that goes to the Setting's app")
  }
  
}

// MARK: - Bookings

extension Loc {
  
  @objc public static var UpdatingTrip: String {
    return NSLocalizedString("Updating trip", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Message that shows app is updating trip after user finalised bookings")
  }

  @objc public static var ValuesMissing: String {
    return NSLocalizedString("Values missing from required fields.", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Message that informs users that some values are missing from the required fields in a booking form.")
  }
  
  @objc public static var YouNeedToAgreeToTheBookingTerms: String {
    return NSLocalizedString("You need to agree to the booking terms and conditions.", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Message that informs users that T&C must be agreed before booking can be made.")
  }
  
  @objc public static var YouNeedToAgreeToTheInsuranceTerms: String {
    return NSLocalizedString("You need to agree to the insurance terms and conditions.", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Message that informs users that T&C for insurance must be agreed before booking can be made.")
  }
  
  @objc public static var JohnAppleseed: String {
    return NSLocalizedString("John Appleseed", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Name placeholder text")
  }
  
  @objc public static var ExampleMail: String {
    return NSLocalizedString("example@example.com", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Email placeholder text")
  }
  
  @objc public static var OpenInSafari: String {
    return NSLocalizedString("Open in Safari", tableName: "Shared", bundle: SGStyleManager.bundle(), comment: "Open in Safari action")
  }
  
}
