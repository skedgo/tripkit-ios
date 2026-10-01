//
//  TKUITripCellFormatterTest.swift
//  TripKitUITests
//
//  RM26218 — results for services that don't run every day can be on a later
//  day than the requested time, which the trip cell should call out.
//

#if canImport(Testing)

import Foundation
import Testing

@testable import TripKitUI

struct TKUITripCellFormatterTest {

  private let darwin = TimeZone(identifier: "Australia/Darwin")!

  private func date(_ string: String) -> Date {
    let formatter = ISO8601DateFormatter()
    return formatter.date(from: string)!
  }

  @Test func sameDayHasNoOffset() {
    let requested = date("2026-09-26T06:36:00+09:30")
    let departure = date("2026-09-26T23:59:00+09:30")
    #expect(TKUITripCell.Formatter.dayOffset(of: departure, from: requested, in: darwin) == 0)
  }

  @Test func laterDaysHavePositiveOffset() {
    // Saturday request, with Monday-to-Friday services on Mon, Tue and Wed
    let requested = date("2026-09-26T06:36:00+09:30")
    #expect(TKUITripCell.Formatter.dayOffset(of: date("2026-09-28T07:03:00+09:30"), from: requested, in: darwin) == 2)
    #expect(TKUITripCell.Formatter.dayOffset(of: date("2026-09-29T07:03:00+09:30"), from: requested, in: darwin) == 3)

    // Just after midnight is the next day
    #expect(TKUITripCell.Formatter.dayOffset(of: date("2026-09-27T00:05:00+09:30"), from: requested, in: darwin) == 1)
  }

  @Test func earlierDaysHaveNegativeOffset() {
    // Arrive-by query for early on a day, with a trip arriving the night before
    let requested = date("2026-09-28T06:00:00+09:30")
    let arrival = date("2026-09-27T22:30:00+09:30")
    #expect(TKUITripCell.Formatter.dayOffset(of: arrival, from: requested, in: darwin) == -1)
  }

  @Test func offsetUsesTimeZoneOfTrip() {
    // Same instants, but in Sydney it's already the next day for the departure
    let sydney = TimeZone(identifier: "Australia/Sydney")!
    let requested = date("2026-09-26T21:00:00+09:30") // 21:30 in Sydney
    let departure = date("2026-09-26T23:00:00+09:30") // 23:30 in Sydney, i.e., still the same day
    let later = date("2026-09-26T23:45:00+09:30")     // 00:15 in Sydney
    #expect(TKUITripCell.Formatter.dayOffset(of: departure, from: requested, in: sydney) == 0)
    #expect(TKUITripCell.Formatter.dayOffset(of: later, from: requested, in: sydney) == 1)
    #expect(TKUITripCell.Formatter.dayOffset(of: later, from: requested, in: darwin) == 0)
  }

  @Test func offsetString() {
    #expect(TKUITripCell.Formatter.dayOffsetString(0) == nil)

    // Content is localised, so only check the sign and the number
    let plusOne = TKUITripCell.Formatter.dayOffsetString(1)
    #expect(plusOne?.hasPrefix("+") == true)
    #expect(plusOne?.contains("1") == true)

    let minusTwo = TKUITripCell.Formatter.dayOffsetString(-2)
    #expect(minusTwo?.hasPrefix("−") == true)
    #expect(minusTwo?.contains("2") == true)
  }

  @Test func weekdayOnlyWhenRequested() {
    let departure = date("2026-09-28T07:03:00+09:30")
    let arrival = date("2026-09-28T07:55:00+09:30")

    let plain = TKUITripCell.Formatter.primaryTimeString(departure: departure, arrival: arrival, departureTimeZone: darwin, arrivalTimeZone: darwin, focusOnDuration: false, isArriveBefore: false)
    let withWeekday = TKUITripCell.Formatter.primaryTimeString(departure: departure, arrival: arrival, departureTimeZone: darwin, arrivalTimeZone: darwin, focusOnDuration: false, isArriveBefore: false, showWeekday: true)

    #expect(withWeekday.hasSuffix(plain))
    #expect(withWeekday.count > plain.count)
  }

}

#endif
