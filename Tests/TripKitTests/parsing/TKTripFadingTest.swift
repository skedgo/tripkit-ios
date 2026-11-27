//
//  TKTripFadingTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 27/11/2026.
//  Copyright © 2026 SkedGo Pty Ltd. All rights reserved.
//

#if canImport(Testing) && canImport(CoreData)

import Foundation
import CoreData
import Testing

@testable import TripKitAPI
@testable import TripKit

/// Faded trips are those that the results show greyed out, and that RoutingSpecKit
/// mustn't pick as a best trip; both sides use this rule.
@MainActor
struct TKTripFadingTest {
  private static let model = TKTestCase.model

  @Test func toleratesSlightlyEarlyDepartures() {
    #expect(!TKTripFading.isFaded(queryOffset: -60, isCanceled: false, missedBookingWindow: false))
    #expect(TKTripFading.isFaded(queryOffset: -61, isCanceled: false, missedBookingWindow: false))
    #expect(!TKTripFading.isFaded(queryOffset: 600, isCanceled: false, missedBookingWindow: false))
  }

  @Test func fadesUnavailableTrips() {
    #expect(TKTripFading.isFaded(queryOffset: 600, isCanceled: true, missedBookingWindow: false))
    #expect(TKTripFading.isFaded(queryOffset: 600, isCanceled: false, missedBookingWindow: true))
  }

  @Test func offsetIsFromQueriedTime() {
    let departure = Date(timeIntervalSince1970: 10_000)
    let arrival = Date(timeIntervalSince1970: 13_000)
    #expect(TKTripFading.queryOffset(departure: departure, arrival: arrival, leaveAfter: departure.addingTimeInterval(90), arriveBy: nil) == -90)
    #expect(TKTripFading.queryOffset(departure: departure, arrival: arrival, leaveAfter: nil, arriveBy: arrival.addingTimeInterval(120)) == 120)
    #expect(TKTripFading.queryOffset(departure: departure, arrival: arrival, leaveAfter: nil, arriveBy: nil, now: departure.addingTimeInterval(-30)) == 30)
  }

  /// The query is for 15:46:30, so the 15:45 buses that day and all trips on
  /// earlier days are faded, as are the trips on Dec 1 and 2.
  @Test func rawAndCoreDataTripsAgree() throws {
    let response = try JSONDecoder().decode(TKAPI.RoutingResponse.self, from: dataFromJSON(named: "routing-pt-darwin"))
    let rawTrips = (response.groups ?? []).flatMap(\.trips)
    let fadedRaw = rawTrips.filter { $0.isFaded(for: response.query) }
    #expect(rawTrips.count == 14)
    #expect(fadedRaw.count == 6)

    let request = try TKRoutingParser.addBlocking(response, into: makeContext())
    let fadedIDs = Set(request.trips.filter(\.isFaded).compactMap(\.tripId))
    #expect(fadedIDs == Set(fadedRaw.compactMap(\.id)))

    // The 15:45 departure on the queried day, 90 seconds early
    #expect(fadedIDs.contains("ccd29efe-4b7d-49ae-a8df-eb12835d8a25"))
    // The 16:10 departure that day
    #expect(!fadedIDs.contains("44699b7d-987f-49aa-825e-2266760bdc9b"))
  }

  /// Without a query time, the request leaves after the earliest trip, so that
  /// none of them count as too early, rather than after an arbitrary one.
  @Test func requestWithoutQueryTimeFadesNoTrips() throws {
    let response = try JSONDecoder().decode(TKAPI.RoutingResponse.self, from: dataFromJSON(named: "routing-with-stops"))
    #expect(response.query == nil)
    let request = try TKRoutingParser.addBlocking(response, into: makeContext())

    #expect(request.trips.count == 16)
    #expect(request.trips.filter(\.isFaded).isEmpty)
    #expect(request.departureTime == request.trips.map(\.departureTime).min())
  }

  /// Groups show their best unfaded trip, like the results list's rows do,
  /// rather than the faded 15:45 bus that has the lowest score of all.
  @Test func visibleTripsAreNotFaded() throws {
    let response = try JSONDecoder().decode(TKAPI.RoutingResponse.self, from: dataFromJSON(named: "routing-pt-darwin"))
    let request = try TKRoutingParser.addBlocking(response, into: makeContext())

    let visibleIDs = Set(request.tripGroups.compactMap(\.visibleTrip?.tripId))
    #expect(visibleIDs == [
      "44699b7d-987f-49aa-825e-2266760bdc9b", // 16:10 on Dec 3, route 447
      "7ed3a884-60c6-4ce3-a57e-c93f904ce36f", // 15:45 on Dec 4, route 450
    ])
  }
}

private extension TKTripFadingTest {

  enum SetupError: Error {
    case missingModel
    case missingFixture(String)
  }

  func makeContext() throws -> NSManagedObjectContext {
    guard let model = Self.model else { throw SetupError.missingModel }

    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
    try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)

    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = coordinator
    return context
  }

  func dataFromJSON(named name: String) throws -> Data {
    let jsonPath = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("Data", isDirectory: true)
      .appendingPathComponent(name)
      .appendingPathExtension("json")

    guard FileManager.default.fileExists(atPath: jsonPath.path) else {
      throw SetupError.missingFixture(jsonPath.path)
    }
    return try Data(contentsOf: jsonPath)
  }
}

#endif
