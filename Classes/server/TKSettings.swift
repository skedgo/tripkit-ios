//
//  TKSettings.swift
//  TripKit
//
//  Created by Adrian Schoenig on 4/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension TKSettings {
  
  public static let parserJsonVersion: Int = 13
  
  private enum DefaultsKey: String {
    case sortIndex = "internalSortIndex"
  }
  
  public static var sortOrder: STKTripCostType {
    get {
      let index = UserDefaults.shared.integer(forKey: DefaultsKey.sortIndex.rawValue)
      return STKTripCostType(rawValue: index) ?? .score
    }
    set {
      UserDefaults.shared.set(newValue.rawValue, forKey: DefaultsKey.sortIndex.rawValue)
    }
  }
  
}
