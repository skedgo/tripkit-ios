//
//  TKUITimePickerSheet+Configuration.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 3/11/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

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
  }
  
}
