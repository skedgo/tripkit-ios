//
//  SegmentTemplate+Flags.swift
//  TripKit
//
//  Created by Adrian Schönig on 13/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension SegmentTemplate {
  
  var hasCarParks: Bool {
    get { has(.hasCarParks) }
    set { set(.hasCarParks, to: newValue) }
  }
  
  var isContinuation: Bool {
    get { has(.isContinuation) }
    set { set(.isContinuation, to: newValue) }
  }
  
  // MARK: -
  
  private struct FlagOptions: OptionSet {
    let rawValue: Int16
    
    static let isContinuation   = FlagOptions(rawValue: 1 << 0)
    static let hasCarParks    = FlagOptions(rawValue: 1 << 1)
  }
  
  private func set(_ option: FlagOptions, to value: Bool) {
    var flags = FlagOptions(rawValue: self.flags?.int16Value ?? 0)
    if value {
      flags.insert(option)
    } else {
      flags.remove(option)
    }
    self.flags = NSNumber(value: flags.rawValue)
  }
  
  private func has(_ option: FlagOptions) -> Bool {
    let flags = FlagOptions(rawValue: self.flags?.int16Value ?? 0)
    return flags.contains(option)
  }
  
}
