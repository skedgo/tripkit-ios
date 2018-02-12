//
//  NSUserDefaults+SharedDefaults.swift
//  TripKit
//
//  Created by Adrian Schoenig on 20/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension UserDefaults {

  public static let shared = UserDefaults.__shared()
  
}
