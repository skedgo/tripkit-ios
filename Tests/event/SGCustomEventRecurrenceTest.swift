//
//  SGCustomEventRecurrenceTest.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 16/07/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import XCTest

@testable import TripKit

class SGCustomEventRecurrenceTest: XCTestCase {

  let sydney = TimeZone(identifier: "Australia/Sydney")!
  let london = TimeZone(identifier: "Europe/London")!
  let santiago = TimeZone(identifier: "America/Santiago")!
  let lordHowe = TimeZone(identifier: "Australia/Lord_Howe")!
  
  func testWeekdayNineToFiveRecurrence() {
    for timeZone in [
      TimeZone.current,
      sydney,
      london,
      santiago,
      ]
    {

      let start = Date.from("2016-05-28 0:00", timeZone: timeZone) // Start of Saturday
      let end   = Date.from("2016-06-06 0:00", timeZone: timeZone) // Start of Monday

      var starts = [Date]()
      var ends   = [Date]()

      TKCustomEventRecurrenceRule.enumerateRecurrences(
        ofRule: "W0111110",
        startTime: 9*3600,
        duration: 8*3600,
        earliest: start,
        latest: end,
        for: timeZone
      ) { startDate, endDate in
        starts.append(startDate)
        ends.append(endDate)
      }
      
      XCTAssertEqual(starts.count, 5, "In \(timeZone) (local time zone is \(TimeZone.current))")
      
      XCTAssertEqual(starts, [
        Date.from("2016-05-30 9:00", timeZone: timeZone),
        Date.from("2016-05-31 9:00", timeZone: timeZone),
        Date.from("2016-06-01 9:00", timeZone: timeZone),
        Date.from("2016-06-02 9:00", timeZone: timeZone),
        Date.from("2016-06-03 9:00", timeZone: timeZone),
        ], "In \(timeZone) (local time zone is \(TimeZone.current))")
      
      XCTAssertEqual(ends, [
        Date.from("2016-05-30 17:00", timeZone: timeZone),
        Date.from("2016-05-31 17:00", timeZone: timeZone),
        Date.from("2016-06-01 17:00", timeZone: timeZone),
        Date.from("2016-06-02 17:00", timeZone: timeZone),
        Date.from("2016-06-03 17:00", timeZone: timeZone),
        ], "In \(timeZone) (local time zone is \(TimeZone.current))")

    }
    
  }
  
  func testRecurrencesCrossingSydneyDaylightSavings() {
    let start = Date.from("2014-04-05 0:00") // Start of Saturday
    let end   = Date.from("2014-04-08 0:00") // Start of Tuesday
    
    var starts = [Date]()
    
    TKCustomEventRecurrenceRule.enumerateRecurrences(
      ofRule: "W1111111",
      startTime: 10*3600,
      duration: 1*3600,
      earliest: start,
      latest: end,
      for: TimeZone.current
    ) { startDate, endDate in
      starts.append(startDate)
    }
    
    XCTAssertEqual(starts.count, 3)
    
    XCTAssertEqual(starts, [
      Date.from("2014-04-05 10:00"),
      Date.from("2014-04-06 10:00"),
      Date.from("2014-04-07 10:00"),
      ])
  }
  
  func testLordHowe30MinsDST() {
    let start = Date.from("2016-10-01 0:00", timeZone: lordHowe) // Start of Saturday
    let end   = Date.from("2016-10-04 0:00", timeZone: lordHowe) // Start of Tuesday
    
    var starts = [Date]()
    
    TKCustomEventRecurrenceRule.enumerateRecurrences(
      ofRule: "W1111111",
      startTime: 10*3600,
      duration: 1*3600,
      earliest: start,
      latest: end,
      for: lordHowe
    ) { startDate, endDate in
      starts.append(startDate)
    }
    
    XCTAssertEqual(starts.count, 3)
    
    XCTAssertEqual(starts, [
      Date.from("2016-10-01 10:00", timeZone: lordHowe),
      Date.from("2016-10-02 10:00", timeZone: lordHowe),
      Date.from("2016-10-03 10:00", timeZone: lordHowe),
      ])
  }
  
  func testAtStartTime() {
    let start = Date.from("2016-09-19 12:00") // Monday
    let end   = Date.from("2016-09-20 12:00") // Tuesday
    
    var starts = [Date]()
    
    TKCustomEventRecurrenceRule.enumerateRecurrences(
      ofRule: "W1111111",
      startTime: 10*3600,
      duration: 1*3600,
      earliest: start,
      latest: end,
      for: TimeZone.current
    ) { startDate, endDate in
      starts.append(startDate)
    }
    
    XCTAssertEqual(starts.count, 1)
    
    XCTAssertEqual(starts, [
      Date.from("2016-09-20 10:00"),
      ])
  }
  
  func testAtEndTime() {
    let start = Date.from("2016-09-19 0:00") // Monday
    let end   = Date.from("2016-09-20 23:59") // Tuesday
    
    var starts = [Date]()
    
    TKCustomEventRecurrenceRule.enumerateRecurrences(
      ofRule: "W1111111",
      startTime: 23*3600,
      duration: 2*3600,
      earliest: start,
      latest: end,
      for: TimeZone.current
    ) { startDate, endDate in
      starts.append(startDate)
    }
    
    XCTAssertEqual(starts.count, 2)
    
    XCTAssertEqual(starts, [
      Date.from("2016-09-19 23:00"),
      Date.from("2016-09-20 23:00"),
      ])
  }
  
  func testLongRecurrenceInShortQuery() {

    var starts = [Date]()
    
    TKCustomEventRecurrenceRule.enumerateRecurrences(
      ofRule: "W1111111",
      startTime: 9*3600,
      duration: 8*3600,
      earliest: Date.from("2016-09-20 14:30"), // Tuesday
      latest: Date.from("2016-09-21  0:00"), // Tuesday
      for: TimeZone.current
    ) { startDate, endDate in
      starts.append(startDate)
    }
    
    XCTAssertEqual(starts.count, 1)
    
    XCTAssertEqual(starts, [
      Date.from("2016-09-20 9:00"),
      ])
    
  }
  
}

extension Date {
  fileprivate static func from(_ string: String, timeZone: TimeZone? = nil) -> Date {
    let formatter = DateFormatter()
    formatter.dateFormat = "YY-MM-dd' 'HH:mm"
    formatter.timeZone = timeZone
    return formatter.date(from: string)!
  }
}
