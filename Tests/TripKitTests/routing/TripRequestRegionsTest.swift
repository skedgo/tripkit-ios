//
//  TripRequestRegionsTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 02/09/2026.
//  Copyright © 2026 SkedGo Pty Ltd. All rights reserved.
//

#if canImport(Testing) && canImport(CoreData)

import Foundation
import CoreData
import CoreLocation
import Testing

@testable import TripKitAPI
@testable import TripKit

/// Covers how a `TripRequest` resolves its regions while an endpoint is still
/// unresolved, e.g., the "Current Location" placeholder whose coordinate only
/// gets filled in when routing.
///
/// Regression test for the "only a walking trip" bug: the mode picker derived
/// its list from `spanningRegion`, which fell back to the international region
/// for an unresolved origin, and `startRegion`/`endRegion` cached that empty
/// lookup forever.
@Suite(.serialized)
@MainActor
struct TripRequestRegionsTest {
  private static let model = TKTestCase.model

  private let sydneyCBD = CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)
  private let northSydney = CLLocationCoordinate2D(latitude: -33.8398, longitude: 151.2095)
  private let melbourneCBD = CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631)
  private let southPacific = CLLocationCoordinate2D(latitude: -40, longitude: -130)
  private let southPacificToo = CLLocationCoordinate2D(latitude: -41, longitude: -131)

  private let context: NSManagedObjectContext

  init() async throws {
    context = try Self.makeContext()

    let data = try Self.dataFromJSON(named: "regions")
    let response = try JSONDecoder().decode(TKAPI.RegionsResponse.self, from: data)
    await TKRegionManager.shared.updateRegions(from: response)
  }

  @Test func resolvedEndpointsInSameRegion() {
    let request = request(from: sydneyCBD, to: northSydney)
    #expect(request.startRegion?.code == "AU_NSW_Sydney")
    #expect(request.endRegion?.code == "AU_NSW_Sydney")
    #expect(request.spanningRegion.code == "AU_NSW_Sydney")
    #expect(request.regionsForModeSelection.map(\.code) == ["AU_NSW_Sydney"])
  }

  @Test func resolvedEndpointsAcrossRegionsIncludeInternational() {
    let request = request(from: sydneyCBD, to: melbourneCBD)
    #expect(request.startRegion?.code == "AU_NSW_Sydney")
    #expect(request.endRegion?.code == "AU_VIC_Melbourne")
    #expect(request.spanningRegion.isInternational)
    #expect(request.regionsForModeSelection.map(\.code) == ["AU_NSW_Sydney", "AU_VIC_Melbourne", TKRegion.international.code])
  }

  @Test func resolvedEndpointsOutsideAnyRegionFallBackToInternational() {
    let request = request(from: southPacific, to: southPacificToo)
    #expect(request.startRegion == nil)
    #expect(request.endRegion == nil)
    #expect(request.regionsForModeSelection.map(\.code) == [TKRegion.international.code])
  }

  /// The "Current Location" placeholder has an invalid coordinate until the
  /// fetcher fills it in. Without a known user location, the destination is
  /// all we can go by, and that's what the mode selection should use rather
  /// than the international fallback.
  @Test func unresolvedOriginUsesDestinationRegionForModes() {
    let request = request(from: kCLLocationCoordinate2DInvalid, to: northSydney)
    #expect(request.startRegion == nil)
    #expect(request.endRegion == nil)
    #expect(request.spanningRegion.isInternational, "Documents the fallback that the mode selection must not rely on")
    #expect(request.regionsForModeSelection.map(\.code) == ["AU_NSW_Sydney"])
  }

  @Test func unresolvedEndpointsYieldNoRegionsForModes() {
    let request = request(from: kCLLocationCoordinate2DInvalid, to: kCLLocationCoordinate2DInvalid)
    #expect(request.regionsForModeSelection.isEmpty)
  }

  @Test func emptyRegionLookupIsNotCached() {
    let request = request(from: kCLLocationCoordinate2DInvalid, to: northSydney)
    #expect(request.startRegion == nil, "Nothing to resolve yet")

    // This is what `TKUIResultsFetcher` does once it has the user's location
    request.fromLocation = TKNamedCoordinate(coordinate: sydneyCBD)

    #expect(request.startRegion?.code == "AU_NSW_Sydney")
    #expect(request.endRegion?.code == "AU_NSW_Sydney")
    #expect(request.regionsForModeSelection.map(\.code) == ["AU_NSW_Sydney"])
  }

}

private extension TripRequestRegionsTest {

  enum SetupError: Error {
    case missingModel
    case missingFixture(String)
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

  static func dataFromJSON(named name: String) throws -> Data {
    let thisSourceFile = URL(fileURLWithPath: #filePath)
    let thisDirectory = thisSourceFile.deletingLastPathComponent()
    let jsonPath = thisDirectory
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
