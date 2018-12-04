//
//  TKBookingAvailabilityTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 29.10.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import XCTest

@testable import TripKit

class TKBookingAvailabilityTest: XCTestCase {
  
  let availability: API.BookingAvailability = {
    let json = """
    {
      "lastUpdated": "2018-10-29T14:38:00Z",
      "intervals": [
        {
          "end": "2018-10-29T02:00:00Z",
          "status": "NOT_AVAILABLE"
        },
        {
          "start": "2018-10-29T02:00:00Z",
          "end": "2018-10-29T06:00:00Z",
          "status": "AVAILABLE"
        },
        {
          "start": "2018-10-29T06:00:00Z",
          "end": "2018-10-29T08:00:00Z",
          "status": "NOT_AVAILABLE"
        },
        {
          "start": "2018-10-29T08:00:00Z",
          "end": "2018-10-29T18:00:00Z",
          "status": "AVAILABLE"
        },
        {
          "start": "2018-10-29T18:00:00Z",
          "status": "UNKNOWN"
        }
      ]
    }
    """
    
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try! decoder.decode(API.BookingAvailability.self, from: json.data(using: .utf8)!)
  }()
  
  func time(_ time: String) -> Date {
    let formatter = ISO8601DateFormatter()
    return formatter.date(from: "2018-10-29T\(time):00Z")!
  }
  

  func testDidParse() throws {
    XCTAssertEqual(availability.intervals.count, 5)
  }
  
  func testContainsDate() throws {
    XCTAssertEqual(availability.getAvailability(at: time("00:00"))?.status, .notAvailable)
    XCTAssertEqual(availability.getAvailability(at: time("02:00"))?.status, .available)
    XCTAssertEqual(availability.getAvailability(at: time("04:00"))?.status, .available)
    XCTAssertEqual(availability.getAvailability(at: time("06:00"))?.status, .notAvailable)
    XCTAssertEqual(availability.getAvailability(at: time("07:00"))?.status, .notAvailable)
    XCTAssertEqual(availability.getAvailability(at: time("08:00"))?.status, .available)
    XCTAssertEqual(availability.getAvailability(at: time("14:38"))?.status, .available)
    XCTAssertEqual(availability.getAvailability(at: time("18:00"))?.status, .unknown)
    XCTAssertEqual(availability.getAvailability(at: time("20:00"))?.status, .unknown)
  }
  
  func testOverlaps() throws {
    XCTAssertEqual(availability.getStatus(start: time("00:00"), end: time("01:00")), .notAvailable)
    XCTAssertEqual(availability.getStatus(start: time("01:00"), end: time("02:00")), .notAvailable)
    XCTAssertEqual(availability.getStatus(start: time("01:00"), end: time("03:00")), .notAvailable)
    XCTAssertEqual(availability.getStatus(start: time("02:00"), end: time("04:00")), .available)
    XCTAssertEqual(availability.getStatus(start: time("03:00"), end: time("05:00")), .available)
    XCTAssertEqual(availability.getStatus(start: time("03:00"), end: time("06:00")), .available)
    XCTAssertEqual(availability.getStatus(start: time("07:00"), end: time("07:30")), .notAvailable)
    XCTAssertEqual(availability.getStatus(start: time("07:00"), end: time("07:30")), .notAvailable)
    XCTAssertEqual(availability.getStatus(start: time("07:00"), end: time("08:00")), .notAvailable)
    XCTAssertEqual(availability.getStatus(start: time("07:00"), end: time("09:00")), .notAvailable)
    XCTAssertEqual(availability.getStatus(start: time("03:00"), end: time("16:00")), .notAvailable)
    XCTAssertEqual(availability.getStatus(start: time("08:00"), end: time("09:00")), .available)
    XCTAssertEqual(availability.getStatus(start: time("09:00"), end: time("10:00")), .available)
    XCTAssertEqual(availability.getStatus(start: time("08:00"), end: time("18:00")), .available)
    XCTAssertEqual(availability.getStatus(start: time("07:00"), end: time("19:00")), .notAvailable)
    XCTAssertEqual(availability.getStatus(start: time("17:00"), end: time("19:00")), .unknown)
    XCTAssertEqual(availability.getStatus(start: time("18:00"), end: time("19:00")), .unknown)
    XCTAssertEqual(availability.getStatus(start: time("20:00"), end: time("22:00")), .unknown)
  }

}
