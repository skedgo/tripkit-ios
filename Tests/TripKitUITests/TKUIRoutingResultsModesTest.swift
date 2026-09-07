//
//  TKUIRoutingResultsModesTest.swift
//  TripKitUITests
//
//  Created by Adrian Schönig on 02/09/2026.
//  Copyright © 2026 SkedGo Pty Ltd. All rights reserved.
//

#if canImport(Testing)

import Foundation
import CoreData
import CoreLocation
import Testing

@testable import TripKitAPI
@testable import TripKit
@testable import TripKitUI

/// Covers how `TKUIRoutingResultsViewModel` derives the selectable modes while
/// the request's origin is still unresolved, i.e., the "Current Location"
/// placeholder whose coordinate only gets filled in when routing.
///
/// Regression tests for the "only a walking trip" bug, where the list fell back
/// to the international region's modes (flight, PT, car, motorbike) and then got
/// written back into `TKSettings` as the user's preferences.
@Suite(.serialized)
@MainActor
struct TKUIRoutingResultsModesTest {
  private static let model = TKTestCase.model

  private let sydneyCBD = CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)
  private let northSydney = CLLocationCoordinate2D(latitude: -33.8398, longitude: 151.2095)

  private let context: NSManagedObjectContext

  init() async throws {
    context = try Self.makeContext()

    TKUIRoutingResultsCard.config = .empty
    TKSettings.showWheelchairInformation = false
    TKSettings.hiddenModeIdentifiers = []

    // Deliberately the *same* fixture the other region-dependent suites use.
    // `TKRegionManager.shared` is global and suites run in parallel, so seeding a
    // different subset here leaks into them - a Sydney-only set made
    // `TripRequestRegionsTest`'s cross-region expectations fail on CI.
    let response = try JSONDecoder().decode(TKAPI.RegionsResponse.self, from: Self.regionsFixture())
    await TKRegionManager.shared.updateRegions(from: response)
  }

  @Test func resolvedRequestOffersRegionModes() {
    let request = request(from: sydneyCBD, to: northSydney)
    let available = TKUIRoutingResultsViewModel.buildAvailableModes(for: request, mutable: true)
    let identifiers = Set(available?.available.map(\.identifier) ?? [])
    #expect(identifiers.isSuperset(of: ["pt_pub", "cy_bic", "ps_tax", "me_car", "wa_wal"]))
    #expect(available?.enabled == ["pt_pub", "cy_bic", "ps_tax", "me_car", "me_mot", "wa_wal"], "School buses are hidden by default")
  }

  @Test func unresolvedOriginUsesDestinationRegionModes() {
    // The state the international fallback used to leave behind
    TKSettings.hiddenModeIdentifiers = ["pt_pub", "me_car", "me_mot"]
    defer { TKSettings.hiddenModeIdentifiers = [] }

    let request = request(from: kCLLocationCoordinate2DInvalid, to: northSydney)
    let available = TKUIRoutingResultsViewModel.buildAvailableModes(for: request, mutable: true)
    let identifiers = Set(available?.available.map(\.identifier) ?? [])
    #expect(identifiers.isSuperset(of: ["pt_pub", "cy_bic", "ps_tax", "wa_wal"]))
    #expect(!identifiers.contains(TKTransportMode.flight.modeIdentifier), "Must not fall back to the international region's modes")
    #expect(available?.enabled == ["pt_ltd_SCHOOLBUS", "cy_bic", "ps_tax", "wa_wal"], "Everything not hidden, not just walking")
  }

  @Test func unresolvedEndpointsYieldNoSelectionRatherThanInternationalModes() {
    let request = request(from: kCLLocationCoordinate2DInvalid, to: kCLLocationCoordinate2DInvalid)
    let available = TKUIRoutingResultsViewModel.buildAvailableModes(for: request, mutable: true)
    #expect(available != nil, "Needs to emit so that fetching can start")
    #expect(available == TKUIRoutingResultsViewModel.AvailableModes.none, "Leaves it to the router to determine the modes")
  }

  @Test func rereadingModesDoesNotWriteSettings() {
    TKSettings.hiddenModeIdentifiers = ["me_car"]
    defer { TKSettings.hiddenModeIdentifiers = [] }

    let request = request(from: sydneyCBD, to: northSydney)
    let updated = TKUIRoutingResultsViewModel.updateAvailableModes(enabled: nil, request: request)
    #expect(updated?.enabled == ["pt_pub", "pt_ltd_SCHOOLBUS", "cy_bic", "ps_tax", "me_mot", "wa_wal"], "Explicitly setting the hidden modes also un-hides the school buses that are only hidden by default")
    #expect(TKSettings.hiddenModeIdentifiers == ["me_car"], "Re-reading must leave the settings untouched")
  }

  @Test func rereadingModesWithUnresolvedEndpointsDoesNotWriteSettings() {
    TKSettings.hiddenModeIdentifiers = ["me_car"]
    defer { TKSettings.hiddenModeIdentifiers = [] }

    let request = request(from: kCLLocationCoordinate2DInvalid, to: kCLLocationCoordinate2DInvalid)
    let updated = TKUIRoutingResultsViewModel.updateAvailableModes(enabled: nil, request: request)
    #expect(updated == TKUIRoutingResultsViewModel.AvailableModes.none)
    #expect(TKSettings.hiddenModeIdentifiers == ["me_car"])
  }

  @Test func pickingModesInCardWritesSettings() {
    defer { TKSettings.hiddenModeIdentifiers = [] }

    let request = request(from: sydneyCBD, to: northSydney)
    let updated = TKUIRoutingResultsViewModel.updateAvailableModes(enabled: ["pt_pub", "wa_wal"], request: request)
    #expect(updated?.enabled == ["pt_pub", "wa_wal"])
    #expect(TKSettings.hiddenModeIdentifiers.isSuperset(of: ["cy_bic", "ps_tax", "me_car", "me_mot"]))
    #expect(!TKSettings.hiddenModeIdentifiers.contains("pt_pub"))
  }

}

private extension TKUIRoutingResultsModesTest {

  enum SetupError: Error {
    case missingModel
  }

  enum FixtureError: Error { case missing(String) }
  
  /// The shared `regions.json` fixture, which lives in the TripKitTests target.
  static func regionsFixture() throws -> Data {
    let url = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()          // TripKitUITests
      .deletingLastPathComponent()          // Tests
      .appendingPathComponent("TripKitTests/Data/regions.json")
    guard FileManager.default.fileExists(atPath: url.path) else {
      throw FixtureError.missing(url.path)
    }
    return try Data(contentsOf: url)
  }

  func request(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> TripRequest {
    TripRequest.insert(
      from: TKNamedCoordinate(coordinate: from),
      to: TKNamedCoordinate(coordinate: to),
      for: nil, timeType: .leaveASAP,
      into: context
    )
  }

  static func makeContext() throws -> NSManagedObjectContext {
    guard let model else { throw SetupError.missingModel }

    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
    try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)

    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = coordinator
    return context
  }

}

#endif
