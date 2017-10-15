//
//  TKBookingDecodingTest.swift
//  TripKitTests
//
//  Created by Adrian Schoenig on 12.10.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import XCTest

@testable import TripKit

class TKBookingDecodingTest: XCTestCase {
    
  func testFakeTNCBooking() {
    let fake = TKBooking.Confirmation.fakeTNC()
    XCTAssertEqual(fake.actions?.count, 2)
    XCTAssertNotNil(fake.provider)
    XCTAssertNotNil(fake.status)
    XCTAssertNotNil(fake.vehicle)
    XCTAssertNotNil(fake.purchase)
  }

  func testFakePublicTransportBooking() {
    let fake = TKBooking.Confirmation.fakePublic()
    XCTAssertEqual(fake.actions?.count, 1)
    XCTAssertNil(fake.provider)
    XCTAssertNotNil(fake.status)
    XCTAssertNil(fake.vehicle)
    XCTAssertNil(fake.purchase)
  }
  
}
