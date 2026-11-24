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
