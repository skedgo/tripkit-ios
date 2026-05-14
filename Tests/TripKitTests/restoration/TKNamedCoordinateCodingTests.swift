//
//  TKNamedCoordinateCodingTests.swift
//  TripKitTests
//
//  Regression tests for Redmine #25661 — a corrupted Core Data archive must
//  not crash the host process when decoded through the secure transformer.
//

import Foundation
import XCTest

@testable import TripKit

final class TKNamedCoordinateCodingTests: XCTestCase {

  func testTransformerReturnsNilForGarbageData() {
    let transformer = TKNamedCoordinateValueTransformer()
    let garbage = Data([0x00, 0x01, 0x02, 0x03])
    XCTAssertNil(transformer.transformedValue(garbage))
  }

  func testTransformerReturnsNilForNonDataInput() {
    let transformer = TKNamedCoordinateValueTransformer()
    XCTAssertNil(transformer.transformedValue(nil))
    XCTAssertNil(transformer.transformedValue("not data"))
  }

  func testRoundTripsValidCoordinate() throws {
    let original = TKNamedCoordinate(latitude: -33.8688, longitude: 151.2093, name: "Sydney", address: "NSW, Australia")
    original.data = ["mode": "pt_pub", "tags": ["bus", "ferry"]]

    let data = try NSKeyedArchiver.archivedData(withRootObject: original, requiringSecureCoding: true)
    let transformer = TKNamedCoordinateValueTransformer()
    let decoded = try XCTUnwrap(transformer.transformedValue(data) as? TKNamedCoordinate)

    XCTAssertEqual(decoded.coordinate.latitude, -33.8688, accuracy: 0.0001)
    XCTAssertEqual(decoded.coordinate.longitude, 151.2093, accuracy: 0.0001)
    XCTAssertEqual(decoded.name, "Sydney")
  }

  func testDecodesPayloadContainingNSNullInData() throws {
    let original = TKNamedCoordinate(latitude: -33.8688, longitude: 151.2093, name: "Sydney", address: nil)
    // NSNull is what `JSONSerialization` produces for JSON null values — pre-fix this
    // class was missing from the inner allow-list and would crash the unarchive.
    original.data = ["nullable": NSNull(), "name": "Sydney"]

    let data = try NSKeyedArchiver.archivedData(withRootObject: original, requiringSecureCoding: true)
    let transformer = TKNamedCoordinateValueTransformer()
    let decoded = try XCTUnwrap(transformer.transformedValue(data) as? TKNamedCoordinate)

    XCTAssertEqual(decoded.coordinate.latitude, -33.8688, accuracy: 0.0001)
    XCTAssertTrue(decoded.data["nullable"] is NSNull)
  }

  func testDecodesPayloadContainingNSDateInData() throws {
    let original = TKNamedCoordinate(latitude: 1.0, longitude: 2.0, name: "x", address: nil)
    original.data = ["when": Date(timeIntervalSince1970: 1_700_000_000)]

    let data = try NSKeyedArchiver.archivedData(withRootObject: original, requiringSecureCoding: true)
    let transformer = TKNamedCoordinateValueTransformer()
    XCTAssertNotNil(transformer.transformedValue(data))
  }
}
