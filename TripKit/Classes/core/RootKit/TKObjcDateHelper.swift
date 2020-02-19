//
//  TKObjcDateHelper.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 15/08/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

/// :nodoc:
@objc(TKObjcDateHelper)
public class _TKObjcDateHelper: NSObject {
  
  @objc
  public static func durationString(forSeconds seconds: TimeInterval) -> String {
    return Date.durationString(forSeconds: seconds)
  }
  
  @objc
  public static func durationStringLong(forMinutes minutes: Int) -> String {
    return Date.durationStringLong(forMinutes: minutes)
  }
  
  @objc
  public static func durationString(forMinutes minutes: Int) -> String {
    return Date.durationString(forMinutes: minutes)
  }
  
  @objc
  public static func durationString(forHours hours: Int) -> String {
    return Date.durationString(forHours: hours)
  }
  
  @objc
  public static func durationString(forDays days: Int) -> String {
    return Date.durationString(forDays: days)
  }
  
  @objc
  public static func durationString(forStart start: Date, end: Date) -> String {
    return end.durationSince(start)
  }
  
  @objc
  public static func durationStringLong(forStart start: Date, end: Date) -> String {
    return end.durationLongSince(start)
  }
  
  @objc
  public static func minutes(forStart start: Date, end: Date) -> Int {
    return end.minutesSince(start)
  }
  
}
