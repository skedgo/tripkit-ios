//
//  NSUserDefaults+SharedDefaults.swift
//  TripKit
//
//  Created by Adrian Schoenig on 20/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension UserDefaults {

  /// Shared `UserDefaults`
  ///
  /// Uses the suite defined if ``TKConfig/appGroupName`` is provided, or otherwise the `UserDefaults.standard`.
  public static let shared: UserDefaults = {
    if let shared = UserDefaults(suiteName: TKConfig.shared.appGroupName) {
      return shared
    } else {
      return UserDefaults.standard
    }
  }()
  
}
