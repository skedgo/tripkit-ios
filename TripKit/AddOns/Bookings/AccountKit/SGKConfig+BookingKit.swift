//
//  SGKConfig+BookingKit.swift
//  TripKit
//
//  Created by Adrian Schoenig on 21/11/16.
//
//

import Foundation

extension SGKConfig {
  /// The app ID of your app on Facebook. Required for using
  /// facebook login.
  ///
  /// Value comes from `SGBookingKit.facebookAppPermissions`
  /// in `Config.plist`
  @objc public var facebookAppID: String? {
    return bookingSettings["facebookAppID"] as? String
  }
  
  /// Which permissions you want to use.
  ///
  /// For a list of possible values, see: https://developers.facebook.com/docs/facebook-login/permissions/v2.0
  ///
  /// Value comes from `SGBookingKit.facebookAppPermissions` 
  /// in `Config.plist`
  @objc public var facebookAppPermissions: [String]? {
    return bookingSettings["facebookAppPermissions"] as? [String]
  }
  
  fileprivate var bookingSettings: [String: Any] {
    return (configuration["SGBookingKit"] as? [String: Any]) ?? [:]
  }
}
