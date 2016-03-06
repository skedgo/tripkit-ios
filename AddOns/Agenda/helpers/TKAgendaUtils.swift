//
//  TKAgendaUtils.swift
//  RioGo
//
//  Created by Adrian Schoenig on 6/03/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

extension NSDateComponents {
  func earliestDate() -> NSDate {
    let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
    return calendar!.dateFromComponents(self)!
  }

  func latestDate() -> NSDate {
    return earliestDate().dateByAddingTimeInterval(86400)
  }
}