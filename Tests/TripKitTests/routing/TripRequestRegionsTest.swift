//
//  TripRequestRegionsTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 02/09/2026.
//  Copyright © 2026 SkedGo Pty Ltd. All rights reserved.
//

import XCTest
import CoreLocation

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
class TripRequestRegionsTest: TKTestCase {

  private let sydneyCBD = CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)
  private let northSydney = CLLocationCoordinate2D(latitude: -33.8398, longitude: 151.2095)
  private let melbourneCBD = CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631)
  private let southPacific = CLLocationCoordinate2D(latitude: -40, longitude: -130)
  private let southPacificToo = CLLocationCoordinate2D(latitude: -41, longitude: -131)

  override func setUp() async throws {
    try await super.setUp()

    let data = try dataFromJSON(named: "regions")
    let response = try JSONDecoder().decode(TKAPI.RegionsResponse.self, from: data)
    await TKRegionManager.shared.updateRegions(from: response)
  }

  private func request(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> TripRequest {
    TripRequest.insert(
      from: TKNamedCoordinate(coordinate: from),
      to: TKNamedCoordinate(coordinate: to),
      for: nil, timeType: .leaveASAP,
      into: tripKitContext
    )
  }

  func testResolvedEndpointsInSameRegion() {
    let request = request(from: sydneyCBD, to: northSydney)
    XCTAssertEqual(request.startRegion?.code, "AU_NSW_Sydney")
    XCTAssertEqual(request.endRegion?.code, "AU_NSW_Sydney")
    XCTAssertEqual(request.spanningRegion.code, "AU_NSW_Sydney")
    XCTAssertEqual(request.regionsForModeSelection.map(\.code), ["AU_NSW_Sydney"])
  }

  func testResolvedEndpointsAcrossRegionsIncludeInternational() {
    let request = request(from: sydneyCBD, to: melbourneCBD)
    XCTAssertEqual(request.startRegion?.code, "AU_NSW_Sydney")
    XCTAssertEqual(request.endRegion?.code, "AU_VIC_Melbourne")
    XCTAssertTrue(request.spanningRegion.isInternational)
    XCTAssertEqual(request.regionsForModeSelection.map(\.code), ["AU_NSW_Sydney", "AU_VIC_Melbourne", TKRegion.international.code])
  }

  func testResolvedEndpointsOutsideAnyRegionFallBackToInternational() {
    let request = request(from: southPacific, to: southPacificToo)
    XCTAssertNil(request.startRegion)
    XCTAssertNil(request.endRegion)
    XCTAssertEqual(request.regionsForModeSelection.map(\.code), [TKRegion.international.code])
  }

  func testUnresolvedOriginUsesDestinationRegionForModes() {
    // The "Current Location" placeholder has an invalid coordinate until the
    // fetcher fills it in. Without a known user location, the destination is
    // all we can go by, and that's what the mode selection should use rather
    // than the international fallback.
    let request = request(from: kCLLocationCoordinate2DInvalid, to: northSydney)
    XCTAssertNil(request.startRegion)
    XCTAssertNil(request.endRegion)
    XCTAssertTrue(request.spanningRegion.isInternational, "Documents the fallback that the mode selection must not rely on")
    XCTAssertEqual(request.regionsForModeSelection.map(\.code), ["AU_NSW_Sydney"])
  }

  func testUnresolvedEndpointsYieldNoRegionsForModes() {
    let request = request(from: kCLLocationCoordinate2DInvalid, to: kCLLocationCoordinate2DInvalid)
    XCTAssertTrue(request.regionsForModeSelection.isEmpty)
  }

  func testEmptyRegionLookupIsNotCached() {
    let request = request(from: kCLLocationCoordinate2DInvalid, to: northSydney)
    XCTAssertNil(request.startRegion, "Nothing to resolve yet")

    // This is what `TKUIResultsFetcher` does once it has the user's location
    request.fromLocation = TKNamedCoordinate(coordinate: sydneyCBD)

    XCTAssertEqual(request.startRegion?.code, "AU_NSW_Sydney")
    XCTAssertEqual(request.endRegion?.code, "AU_NSW_Sydney")
    XCTAssertEqual(request.regionsForModeSelection.map(\.code), ["AU_NSW_Sydney"])
  }

}
