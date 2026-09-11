//
//  TKNamedCoordinateAnnotationTest.swift
//  TripKitTests
//
//  Regression tests for RM26188 — `namedCoordinate(for:)` dropped an
//  annotation's title whenever it had no subtitle, e.g. the "Current
//  Location" placeholder, so its title fell back to a generic "…".
//

#if canImport(Testing)

import Testing
import MapKit

@testable import TripKit

@MainActor
struct TKNamedCoordinateAnnotationTest {

  @Test func placeholderKeepsCurrentLocationTitle() {
    let placeholder = TKLocationManager.shared.currentLocation
    let named = TKNamedCoordinate.namedCoordinate(for: placeholder)
    #expect(named.title == Loc.CurrentLocation)
  }

  @Test func titleOnlyAnnotationKeepsItsTitle() {
    let annotation = MKPointAnnotation()
    annotation.coordinate = CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)
    annotation.title = "Some Place"
    // Deliberately no subtitle.

    let named = TKNamedCoordinate.namedCoordinate(for: annotation)
    #expect(named.title == "Some Place")
    #expect(named.address == nil)
  }

  @Test func titleAndSubtitleBecomeNameAndAddress() {
    let annotation = MKPointAnnotation()
    annotation.coordinate = CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)
    annotation.title = "Some Place"
    annotation.subtitle = "42 Example St"

    let named = TKNamedCoordinate.namedCoordinate(for: annotation)
    #expect(named.name == "Some Place")
    #expect(named.address == "42 Example St")
  }

  @Test func namedCoordinateInputReturnsSameInstance() {
    let original = TKNamedCoordinate(latitude: -33.8688, longitude: 151.2093, name: "Some Place", address: nil)
    let named = TKNamedCoordinate.namedCoordinate(for: original)
    #expect(named === original)
  }

  @Test func noTitleFallsBackToGenericLocation() {
    let annotation = MKPointAnnotation()
    annotation.coordinate = CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)
    // Deliberately no title, no subtitle.

    let named = TKNamedCoordinate.namedCoordinate(for: annotation)
    #expect(named.title == Loc.Location)
  }

  @Test func emptySubtitleStaysNilAddress() {
    let annotation = MKPointAnnotation()
    annotation.coordinate = CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)
    annotation.title = "Some Place"
    annotation.subtitle = ""

    let named = TKNamedCoordinate.namedCoordinate(for: annotation)
    #expect(named.name == "Some Place")
    #expect(named.address == nil)
  }

}

#endif
