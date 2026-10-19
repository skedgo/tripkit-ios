//
//  TKTripGoGeocoderTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 17/09/2026.
//  Copyright © 2026 SkedGo Pty Ltd. All rights reserved.
//

#if canImport(Testing) && canImport(MapKit)

import CoreLocation
import MapKit
import Testing

@testable import TripKit

/// Regression test for RM25980: without location permission the map shows all
/// of Australia, and searches were biased to its centre in the outback.
struct TKTripGoGeocoderTest {

  private static let perth = CLLocationCoordinate2D(latitude: -32.05786, longitude: 115.78261)

  @Test(arguments: [
    2_000,  // street
    20_000, // suburb
    80_000, // metro
  ] as [CLLocationDistance])
  func biasesToCentreOfLocalMap(size: CLLocationDistance) {
    let region = MKCoordinateRegion(center: Self.perth, latitudinalMeters: size, longitudinalMeters: size)
    #expect(TKTripGoGeocoder.biasParameter(for: region) == "-32.05786,115.78261")
  }

  @Test func doesNotBiasToCentreOfState() {
    let region = MKCoordinateRegion(center: .init(latitude: -27.69738, longitude: 118.61513), latitudinalMeters: 2_000_000, longitudinalMeters: 1_800_000)
    #expect(TKTripGoGeocoder.biasParameter(for: region) == nil)
  }

  @Test func doesNotBiasToCentreOfCountry() {
    let region = MKCoordinateRegion(center: .init(latitude: -16.98895, longitude: 131.64607), span: .init(latitudeDelta: 40, longitudeDelta: 45))
    #expect(TKTripGoGeocoder.biasParameter(for: region) == nil)
  }

  @Test func doesNotBiasToCentreOfWorld() {
    #expect(TKTripGoGeocoder.biasParameter(for: MKCoordinateRegion(.world)) == nil)
  }

  @Test func doesNotBiasToInvalidCentre() {
    let region = MKCoordinateRegion(center: .invalid, latitudinalMeters: 2_000, longitudinalMeters: 2_000)
    #expect(TKTripGoGeocoder.biasParameter(for: region) == nil)
  }

}

#endif
