//
//  TKUITimePickerSheet+Configuration.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 3/11/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKit

public extension TKUITimePickerSheet {
  
  struct Configuration {
    private init() {}
    
    public static let `default` = Configuration()
    
    /// Minute interval that the user can specify the minutes in.
    ///
    /// Defaults to 1 minute increments.
    public var incrementInterval: Int = 1
    
    /// Whether the picker in `timeType` mode is allowed to display the `leaveASAP` option.
    ///
    /// Defaults to `true`.
    public var allowsASAP: Bool = true
    
    /// Earliest date/time that can be selected
    ///
    /// Defaults to `nil`, i.e., no limit.
    public var minimumDate: Date? = nil

    /// Latest date/time that can be selected
    ///
    /// Defaults to `nil`, i.e., no limit.
    public var maximumDate: Date? = nil
    
    /// Allows customizing the "Leave at" time type label.
    public var leaveAtLabel: String = Loc.LeaveAt
    
    /// Allows customizig the "Arrive by" time type label
    public var arriveByLabel: String = Loc.ArriveBy
    
    /// Controls wether the picker should dismiss when done is tapped.
    public var shouldDismissPicker: Bool = true
    
    /// This controls wether minimum and maximum date is set to 1 month if set to nil
    public var removeDateLimits: Bool = false
  }
  
}
