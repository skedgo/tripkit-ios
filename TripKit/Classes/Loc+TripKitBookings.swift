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
    return NSLocalizedString("Already have an account? Sign in", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Option for users if they already owned a SkedGo account")
  }

  @objc public static var DontHaveAnAccount: String {
    return NSLocalizedString("Don't have an account? Sign up", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Option for users if they don't yet have a SkedGo account")
  }

  @objc public static var Authentication: String {
    return NSLocalizedString("Authentication", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Source where the account was derived, e.g., Facebook")
  }

  @objc public static var SignOut: String {
    return NSLocalizedString("Sign out", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Instruction for signing out user account")
  }

  @objc public static var Mail: String {
    return NSLocalizedString("Email", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "For email address")
  }

  @objc public static var Password: String {
    return NSLocalizedString("Password", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "")
  }

  
  @objc public static var Change: String {
    return NSLocalizedString("Change", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Instruction for changing password")
  }

  @objc public static var AppWillNowSignOut: String {
    return NSLocalizedString("The app will now sign out", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Message that indicates the app is about to sign users out of their user accounts")
  }

  @objc public static var InvalidAccount: String {
    return NSLocalizedString("Invalid account", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Title for alert that indicates the user account has become invalid")
  }
  
  @objc public static var SigningOut: String {
    return NSLocalizedString("Signing out", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Message that indicates the app is signing users out of their accounts")
  }
  
  @objc public static var MyAccount: String {
    return NSLocalizedString("My account", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Title for view that shows the summary of a user's account information")
  }
  
  @objc public static var SignIn: String {
    return NSLocalizedString("Sign in", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Title of page or button to sign in")
  }
  
  @objc public static var SigningIn: String {
    return NSLocalizedString("Signing in", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Message that indicates the app is signing users into their user accounts")
  }
  
  @objc public static var SignUp: String {
    return NSLocalizedString("Sign up", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Title of page or button to sign up")
  }
  
  @objc public static var NewAccount: String {
    return NSLocalizedString("New account", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Title of page to create new account")
  }
  
  @objc public static var CreatingAccount: String {
    return NSLocalizedString("Creating account", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Message that indicates the app is creating accounts for users")
  }
  
  @objc public static var CannotProceedWithoutMail: String {
    return NSLocalizedString("Cannot proceed without a valid email address", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "")
  }
  
  @objc public static var CannotProceedWithoutPassword: String {
    return NSLocalizedString("Sign up cannot be completed without a valid password", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "")
  }
  
  @objc public static var UnknownError: String {
    return NSLocalizedString("Unknown error", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "")
  }
  
  @objc public static var OpenSettings: String {
    return NSLocalizedString("Open Settings", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Button that goes to the Setting's app")
  }
  
}

// MARK: - Bookings

extension Loc {
  
  @objc public static var UpdatingTrip: String {
    return NSLocalizedString("Updating trip", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Message that shows app is updating trip after user finalised bookings")
  }

  @objc public static var ValuesMissing: String {
    return NSLocalizedString("Values missing from required fields.", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Message that informs users that some values are missing from the required fields in a booking form.")
  }
  
  @objc public static var YouNeedToAgreeToTheBookingTerms: String {
    return NSLocalizedString("You need to agree to the booking terms and conditions.", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Message that informs users that T&C must be agreed before booking can be made.")
  }
  
  @objc public static var YouNeedToAgreeToTheInsuranceTerms: String {
    return NSLocalizedString("You need to agree to the insurance terms and conditions.", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Message that informs users that T&C for insurance must be agreed before booking can be made.")
  }
  
  @objc public static var JohnAppleseed: String {
    return NSLocalizedString("John Appleseed", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Name placeholder text")
  }
  
  @objc public static var ExampleMail: String {
    return NSLocalizedString("example@example.com", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Email placeholder text")
  }
  
  @objc public static var OpenInSafari: String {
    return NSLocalizedString("Open in Safari", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Open in Safari action")
  }
  
}

// MARK: - Account

extension Loc {
  
  public static var PrimaryEmailNotSet: String {
    return NSLocalizedString("Primary email is not set on your account. Please contact us for support", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Message to user if no primary email is set on his/her account")
  }
  
  public static var PrimaryEmailNotVerifiedForPasswordChange: String {
    return NSLocalizedString("Primary email must be verified before you can change password. Please follow the link in the email that was sent to you.", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Error message shown to a user when he/she tries to change password without the primary email verified")
  }
  
  public static var PasswordIsEmpty: String {
    return NSLocalizedString("The password field cannot be empty.", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Error message shown to a user when zero-length password field is detected")
  }
  
  public static var InvalidCredentials: String {
    return NSLocalizedString("The username or password you've entered is incorrect.", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Error message shown to a user when he/she enters incorrect username or password")
  }
  
  public static var EditAccount: String {
    return NSLocalizedString("Edit Account", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Title for the screen which allows users to edit their accounts")
  }
  
  public static var ServerError: String {
    return NSLocalizedString("Server Error", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Class of errors generated by our servers")
  }
  
  public static var DataError: String {
    return NSLocalizedString("Data Error", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Class of errors usually originated from databases")
  }
  
  public static var VerifyPassword: String {
    return NSLocalizedString("Verify password", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Prompt for users to enter their passwords for verification purpose.")
  }
  
  public static var EnterNewPassword: String {
    return NSLocalizedString("Enter a new password", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Prompt for users to enter a new password")
  }
  
  public static var PleaseEnterCurrentPasswordForYourSecurity: String {
    return NSLocalizedString("For your security, please enter your current password.", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "A footnote that tells users we are asking for their current passwords, and why.")
  }
  
  public static var SecurePasswordAreAtLeastFiveCharatersLongAndIncludeNumbersAndSymbols: String {
    return NSLocalizedString("For your security, please enter your current password.", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "A footnote that tells users we are asking for their current passwords, and why.")
  }
  
  public static var Verify: String {
    return NSLocalizedString("Verify", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Title for a button which, when tapped, proceeds to verifying password")
  }
  
  public static var Update: String {
    return NSLocalizedString("Update", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Title for a button which, when tapped, proceeds to updating password")
  }
  
  
  
}
