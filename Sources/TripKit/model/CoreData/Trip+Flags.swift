//
//  TripGroup+Flags.swift
//  TripKit
//
//  Created by Adrian Schönig on 13/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension Trip {
  
  public var showNoVehicleUUIDAsLift: Bool {
    get { has(.showNoVehicleUUIDAsLift) }
    set { set(.showNoVehicleUUIDAsLift, to: newValue) }
  }

  public var departureTimeIsFixed: Bool {
    get { has(.hasFixedDeparture) }
    set { set(.hasFixedDeparture, to: newValue) }
  }
  
  public var missedBookingWindow: Bool {
    get { has(.bookingWindowMissed) }
    set { set(.bookingWindowMissed, to: newValue) }
  }
  
  public var hideExactTimes: Bool {
    get { has(.hideExactTimes) }
    set { set(.hideExactTimes, to: newValue) }
  }
  
  @objc // TEMP
  public var isCanceled: Bool {
    get { has(.isCanceled) }
    set { set(.isCanceled, to: newValue) }
  }
  
  // MARK: -

  private struct FlagOptions: OptionSet {
    let rawValue: Int16
    
    static let showNoVehicleUUIDAsLift  = FlagOptions(rawValue: 1 << 1)
    static let hasFixedDeparture        = FlagOptions(rawValue: 1 << 3)
    static let bookingWindowMissed      = FlagOptions(rawValue: 1 << 4)
    static let isCanceled               = FlagOptions(rawValue: 1 << 5)
    static let hideExactTimes           = FlagOptions(rawValue: 1 << 6)
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
