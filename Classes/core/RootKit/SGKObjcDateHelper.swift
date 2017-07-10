//
//  SGKObjcDateHelper.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 15/08/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

public class SGKObjcDateHelper: NSObject {
  public static func durationString(forSeconds seconds: TimeInterval) -> String {
    return Date.durationString(forSeconds: seconds)
  }
  
  public static func durationStringLong(forMinutes minutes: Int) -> String {
    return Date.durationStringLong(forMinutes: minutes)
  }
  
  public static func durationString(forMinutes minutes: Int) -> String {
    return Date.durationString(forMinutes: minutes)
  }
  
  public static func durationString(forHours hours: Int) -> String {
    return Date.durationString(forHours: hours)
  }
  
  public static func durationString(forDays days: Int) -> String {
    return Date.durationString(forDays: days)
  }
  
  public static func durationString(forStart start: Date, end: Date) -> String {
    return end.durationSince(start)
  }
  
  public static func durationStringLong(forStart start: Date, end: Date) -> String {
    return end.durationLongSince(start)
  }
  
  public static func minutes(forStart start: Date, end: Date) -> Int {
    return end.minutesSince(start)
  }
  
}
