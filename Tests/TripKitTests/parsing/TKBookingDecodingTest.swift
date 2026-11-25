//
//  TKBookingDecodingTest.swift
//  TripKitTests
//
//  Created by Adrian Schoenig on 12.10.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

#if canImport(Testing)

import Foundation
import Testing

@testable import TripKit

struct TKBookingDecodingTest {

  @Test func fakeTNCBooking() {
    let fake = TKBooking.Confirmation.fakeTNC()
    #expect(fake.actions?.count == 2)
    #expect(fake.provider != nil)
    #expect(fake.status != nil)
    #expect(fake.vehicle != nil)
    #expect(fake.purchase != nil)
  }

  @Test func fakePublicTransportBooking() {
    let fake = TKBooking.Confirmation.fakePublic()
    #expect(fake.actions?.count == 1)
    #expect(fake.provider == nil)
    #expect(fake.status != nil)
    #expect(fake.vehicle == nil)
    #expect(fake.purchase == nil)
  }

  @Test func bookingEURCurrency() throws {
    let fare = try JSONDecoder().decode(TKBooking.Fare.self, from: Data("""
      {
        "id": "1",
        "name": "In Euro",
        "description": "A fare",
        "price": 300,
        "currency": "EUR"
      }
      """.utf8))
    #expect(fare.priceValue(locale: .init(identifier: "en_AU")) == "EUR 3.00")
    #expect(fare.priceValue(locale: .init(identifier: "en_US")) == "€3.00")
    #expect(fare.priceValue(locale: .init(identifier: "de_DE")) == "3,00 €")
  }

  @Test func bookingAUDCurrency() throws {
    let fare = try JSONDecoder().decode(TKBooking.Fare.self, from: Data("""
      {
        "id": "1",
        "name": "In Aussie Dollar",
        "description": "A fare",
        "price": 300,
        "currency": "AUD"
      }
      """.utf8))
    #expect(fare.priceValue(locale: .init(identifier: "en_AU")) == "$3.00")
    #expect(fare.priceValue(locale: .init(identifier: "en_US")) == "A$3.00")
    #expect(fare.priceValue(locale: .init(identifier: "de_DE")) == "3,00 AU$")
  }


  @Test func bookingUSDCurrency() throws {
    let fare = try JSONDecoder().decode(TKBooking.Fare.self, from: Data("""
      {
        "id": "1",
        "name": "In US Dollar",
        "description": "A fare",
        "price": 300,
        "currency": "USD"
      }
      """.utf8))
    #expect(fare.priceValue(locale: .init(identifier: "en_AU")) == "USD 3.00")
    #expect(fare.priceValue(locale: .init(identifier: "en_US")) == "$3.00")
    #expect(fare.priceValue(locale: .init(identifier: "de_DE")) == "3,00 $")
  }

  @Test func bookingYenCurrency() throws {
    let fare = try JSONDecoder().decode(TKBooking.Fare.self, from: Data("""
      {
        "id": "1",
        "name": "In Yen",
        "description": "A fare",
        "price": 30000,
        "currency": "JPY"
      }
      """.utf8))
    #expect(fare.priceValue(locale: .init(identifier: "en_AU")) == "JPY 300")
    #expect(fare.priceValue(locale: .init(identifier: "en_US")) == "¥300")
    #expect(fare.priceValue(locale: .init(identifier: "de_DE")) == "300 ¥")
  }

  @Test func bookingFareMinAndMax() throws {
    let fare = try JSONDecoder().decode(TKBooking.Fare.self, from: Data("""
      {
        "id": "companion",
        "name": "Additional passenger",
        "price": 100,
        "currency": "USD",
        "min": 1,
        "max": 3
      }
      """.utf8))
    #expect(fare.min == 1)
    #expect(fare.max == 3)

    // And they make it back out when submitting the fare
    let encoded = try JSONEncoder().encode(fare)
    let decoded = try JSONDecoder().decode(TKBooking.Fare.self, from: encoded)
    #expect(decoded.min == 1)
    #expect(decoded.max == 3)
  }

  @Test func bookingFareWithoutMinAndMax() throws {
    let fare = try JSONDecoder().decode(TKBooking.Fare.self, from: Data("""
      {
        "id": "1",
        "name": "Single",
        "price": 300,
        "currency": "USD"
      }
      """.utf8))
    #expect(fare.min == nil)
    #expect(fare.max == nil)
    #expect(fare.amountWhenSelected == 1)
    #expect(fare.validAmount(0) == 0)
    #expect(fare.validAmount(7) == 7)
    #expect(fare.validAmount(stepped: 1, from: 0) == 1)
    #expect(fare.validAmount(stepped: 0, from: 1) == 0)
  }

  @Test func bookingFareAmountsWithMin() throws {
    let fare = try JSONDecoder().decode(TKBooking.Fare.self, from: Data("""
      {
        "id": "companion",
        "name": "Additional passenger",
        "price": 100,
        "currency": "USD",
        "min": 2,
        "max": 4
      }
      """.utf8))

    // Selecting starts at the minimum
    #expect(fare.amountWhenSelected == 2)

    // Min only applies when selected, so none is always fine
    #expect(fare.validAmount(0) == 0)

    // Pre-selected amounts get pulled into the bounds
    #expect(fare.validAmount(1) == 2)
    #expect(fare.validAmount(3) == 3)
    #expect(fare.validAmount(9) == 4)

    // Stepping skips what can't be bought
    #expect(fare.validAmount(stepped: 1, from: 0) == 2)
    #expect(fare.validAmount(stepped: 3, from: 2) == 3)
    #expect(fare.validAmount(stepped: 2, from: 3) == 2)
    #expect(fare.validAmount(stepped: 1, from: 2) == 0)
    #expect(fare.validAmount(stepped: 0, from: 1) == 0)
  }

  @Test func bookingFareWithMinAboveMax() throws {
    // Server shouldn't send this, but don't offer anything beyond the max
    let fare = try JSONDecoder().decode(TKBooking.Fare.self, from: Data("""
      {
        "id": "1",
        "name": "Broken",
        "min": 3,
        "max": 2
      }
      """.utf8))
    #expect(fare.amountWhenSelected == 2)
    #expect(fare.validAmount(1) == 2)
  }

  @Test func bookingTermsInput() throws {
    let freshInput = try JSONDecoder().decode(TKBooking.BookingInput.self, from: Data("""
      {
        "id": "terms",
        "type": "TERMS",
        "title": "Review Terms and Conditions",
        "urlValue": "https://example.com/legal/terms",
        "required": false
      }
      """.utf8))

    #expect(freshInput.type == .terms)
    #expect(freshInput.value == .terms(URL(string: "https://example.com/legal/terms")!, accepted: false))

    let encodedInput = try JSONEncoder().encode(freshInput)
    let decodedInput = try JSONDecoder().decode(TKBooking.BookingInput.self, from: encodedInput)
    #expect(freshInput == decodedInput)
  }

  @Test func bookingAcceptedTermsInput() throws {
    let freshInput = try JSONDecoder().decode(TKBooking.BookingInput.self, from: Data("""
      {
        "id": "terms",
        "type": "TERMS",
        "title": "Review Terms and Conditions",
        "urlValue": "https://example.com/legal/terms",
        "value": "true",
        "required": false
      }
      """.utf8))

    let encodedInput = try JSONEncoder().encode(freshInput)
    let decodedInput = try JSONDecoder().decode(TKBooking.BookingInput.self, from: encodedInput)
    #expect(freshInput == decodedInput)
  }

}

#endif
