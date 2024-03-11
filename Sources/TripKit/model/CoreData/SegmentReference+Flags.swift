//
//  SegmentReference+Flags.swift
//  TripKit
//
//  Created by Adrian Schönig on 13/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension SegmentReference {
  
  var timesAreRealTime: Bool {
    get { has(.timesAreRealTime) }
    set { set(.timesAreRealTime, to: newValue) }
  }

  var isBicycleAccessible: Bool {
    get { has(.bicycleAccessible) }
    set { set(.bicycleAccessible, to: newValue) }
  }
  
  var isWheelchairAccessible: Bool {
    get { has(.wheelchairAccessible) }
    set { set(.wheelchairAccessible, to: newValue) }
  }
  
  var isWheelchairInaccessible: Bool {
    get { has(.wheelchairInaccessible) }
    set { set(.wheelchairInaccessible, to: newValue) }
  }
  
  // MARK: -

  private struct FlagOptions: OptionSet {
    let rawValue: Int16
    
    static let timesAreRealTime       = FlagOptions(rawValue: 1 << 0)
    static let bicycleAccessible      = FlagOptions(rawValue: 1 << 1)
    static let wheelchairAccessible   = FlagOptions(rawValue: 1 << 2)
    static let wheelchairInaccessible = FlagOptions(rawValue: 1 << 3)
  }

  private func set(_ option: FlagOptions, to value: Bool) {
    var flags = FlagOptions(rawValue: self.flags)
    if value {
      flags.insert(option)
    } else {
      flags.remove(option)
    }
    self.flags = flags.rawValue
  }
  
  private func has(_ option: FlagOptions) -> Bool {
    let flags = FlagOptions(rawValue: self.flags)
    return flags.contains(option)
  }
  
}
