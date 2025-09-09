//
//  TKUITimePickerSheet+Configuration.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 3/11/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKit

public struct TKUITimePickerConfiguration {
  
  private init() {}
  
  public static let `default` = TKUITimePickerConfiguration()
  
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
  
  /// Allows customising the "Date & Time" title of the sheet
  public var title: String = Loc.DateAndTime
  
  /// Allows customising the "Leave at" time type label.
  public var leaveAtLabel: String = Loc.LeaveAt
  
  /// Allows customising the "Arrive by" time type label
  public var arriveByLabel: String = Loc.ArriveBy
  
  /// This controls whether minimum and maximum date is set to 1 month if set to nil
  public var removeDateLimits: Bool = false
  
  /// Allows selection of dates that are below or beyond minimum and maximum date respectively.
  /// This makes the selector button be disabled wether current date selected is out of range.
  public var allowsOutOfRangeSelection: Bool = false
  
  /// Customises the time picker use for either sheet or embed (for other view / view controller use)
  ///
  ///  Defaults to .sheet
  ///
  ///  - warning: Deprecated. No longer supported in iOS 26.0 and up.
  public var style: TKUITimePickerSheet.Style = .sheet

}


extension TKUITimePickerSheet {
  
  public typealias Configuration = TKUITimePickerConfiguration
  
}
