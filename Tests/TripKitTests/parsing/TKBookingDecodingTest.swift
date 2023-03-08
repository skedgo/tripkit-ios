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
  
  func testBookingEURCurrency() throws {
    let fare = try JSONDecoder().decode(TKBooking.Fare.self, from: Data("""
      {
        "id": "1",
        "name": "In Euro",
        "description": "A fare",
        "price": 300,
        "currency": "EUR"
      }
      """.utf8))
    XCTAssertEqual(fare.priceValue(locale: .init(identifier: "en_AU")), "EUR 3.00")
    XCTAssertEqual(fare.priceValue(locale: .init(identifier: "en_US")), "€3.00")
    XCTAssertEqual(fare.priceValue(locale: .init(identifier: "de_DE")), "3,00 €")
  }

  func testBookingAUDCurrency() throws {
    let fare = try JSONDecoder().decode(TKBooking.Fare.self, from: Data("""
      {
        "id": "1",
        "name": "In Aussie Dollar",
        "description": "A fare",
        "price": 300,
        "currency": "AUD"
      }
      """.utf8))
    XCTAssertEqual(fare.priceValue(locale: .init(identifier: "en_AU")), "$3.00")
    XCTAssertEqual(fare.priceValue(locale: .init(identifier: "en_US")), "A$3.00")
    XCTAssertEqual(fare.priceValue(locale: .init(identifier: "de_DE")), "3,00 AU$")
  }


  func testBookingUSDCurrency() throws {
    let fare = try JSONDecoder().decode(TKBooking.Fare.self, from: Data("""
      {
        "id": "1",
        "name": "In US Dollar",
        "description": "A fare",
        "price": 300,
        "currency": "USD"
      }
      """.utf8))
    XCTAssertEqual(fare.priceValue(locale: .init(identifier: "en_AU")), "USD 3.00")
    XCTAssertEqual(fare.priceValue(locale: .init(identifier: "en_US")), "$3.00")
    XCTAssertEqual(fare.priceValue(locale: .init(identifier: "de_DE")), "3,00 $")
  }

  func testBookingYenCurrency() throws {
    let fare = try JSONDecoder().decode(TKBooking.Fare.self, from: Data("""
      {
        "id": "1",
        "name": "In Yen",
        "description": "A fare",
        "price": 30000,
        "currency": "JPY"
      }
      """.utf8))
    XCTAssertEqual(fare.priceValue(locale: .init(identifier: "en_AU")), "JPY 300")
    XCTAssertEqual(fare.priceValue(locale: .init(identifier: "en_US")), "¥300")
    XCTAssertEqual(fare.priceValue(locale: .init(identifier: "de_DE")), "300 ¥")
  }

}
