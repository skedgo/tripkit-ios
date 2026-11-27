//
//  TripTimeZoneTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 27/11/2026.
//  Copyright © 2026 SkedGo Pty Ltd. All rights reserved.
//

#if canImport(Testing) && canImport(CoreData)

import Foundation
import CoreData
import Testing

@testable import TripKit

/// Times need to be shown in the time zone that the response states, rather
/// than one inferred from the loaded regions, which can be missing the region
/// and then fell back to the device's.
@MainActor
struct TripTimeZoneTest {
  private static let model = TKTestCase.model

  // No region uses Eucla and no device is set to it, so neither a region
  // lookup nor the fallback to `.current` can produce it.
  private let eucla = TimeZone(identifier: "Australia/Eucla")!

  @Test func tripTimesUseTimeZoneFromResponse() async throws {
    let context = try makeContext()
    let response = try JSONDecoder().decode(
      TKAPI.RoutingResponse.self,
      from: dataFromJSON(named: "routing-pt-darwin", replacing: "Australia/Darwin")
    )

    // Like `TKRouter`, add to a request whose endpoints have no time zone
    let request = TripRequest.insert(
      from: TKNamedCoordinate(coordinate: .init(latitude: -12.4789, longitude: 130.98686)),
      to: TKNamedCoordinate(coordinate: .init(latitude: -12.5474, longitude: 131.122982)),
      for: nil, timeType: .leaveASAP, into: context
    )
    let trips = try await withCheckedThrowingContinuation { continuation in
      TKRoutingParser.add(response, to: request, merge: false) { continuation.resume(with: $0) }
    }

    #expect(trips.count == 14)
    for trip in trips {
      #expect(trip.departureTimeZone == eucla)
      #expect(trip.arrivalTimeZone == eucla)
      for segment in trip.segments {
        #expect(segment.timeZone == eucla, "Wrong time zone for \(segment.order) segment")
      }
    }
  }

  @Test func stopsUseTimeZoneFromResponse() throws {
    let context = try makeContext()
    let departures = try JSONDecoder().decode(
      TKAPI.Departures.self,
      from: dataFromJSON(named: "departures-parentStop", replacing: "Australia/Sydney")
    )

    let parent = StopLocation.fetchOrInsertStop(stopCode: "201510", in: context)
    _ = TKDeparturesProvider.addDepartures(departures, to: [parent])

    #expect(parent.timeZone == eucla)
    let children = parent.children ?? []
    #expect(children.count == 12)
    for child in children {
      #expect(child.timeZone == eucla, "Wrong time zone for stop \(child.stopCode)")
    }
  }
}

private extension TripTimeZoneTest {

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

  /// Loads a fixture with its time zone swapped for Eucla
  func dataFromJSON(named name: String, replacing timeZoneID: String) throws -> Data {
    let jsonPath = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("Data", isDirectory: true)
      .appendingPathComponent(name)
      .appendingPathExtension("json")

    guard FileManager.default.fileExists(atPath: jsonPath.path) else {
      throw SetupError.missingFixture(jsonPath.path)
    }

    let json = try String(decoding: Data(contentsOf: jsonPath), as: UTF8.self)
      .replacingOccurrences(of: timeZoneID, with: eucla.identifier)
    return Data(json.utf8)
  }
}

#endif
