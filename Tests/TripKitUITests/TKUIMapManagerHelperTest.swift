//
//  TKUIMapManagerHelperTest.swift
//  
//
//  Created by Adrian Schönig on 18/8/21.
//

import XCTest

import CoreLocation

@testable import TripKit
@testable import TripKitUI

class TKUIMapManagerHelperTest: TKTestCase {
  
  func testParsingTripAwayFromNetwork11833() throws {
    let request = try self.request(fromFilename: "routing-motorbike")

    XCTAssertNotNil(request)
    let queryFrom = try XCTUnwrap(request.fromLocation.coordinate)
    let queryTo = try XCTUnwrap(request.toLocation.coordinate)

    // reconstructing the query
    let expectedFrom = CLLocationCoordinate2D(latitude: -33.6594, longitude: 151.2237)
    let queryFromDistance = try XCTUnwrap(queryFrom.distance(from: expectedFrom))
    XCTAssertEqual(queryFromDistance, 0, accuracy: 10)
    let expectedTo = CLLocationCoordinate2D(latitude: -33.54381, longitude: 151.21246)
    let queryToDistance = try XCTUnwrap(queryTo.distance(from: expectedTo))
    XCTAssertEqual(queryToDistance, 0, accuracy: 10)

    // basic trip properties
    XCTAssertEqual(request.tripGroups.count, 1)
    XCTAssertEqual(request.trips.count, 1)
    let trip = try XCTUnwrap(request.trips.first)
    XCTAssertEqual(trip.totalScore, 64, accuracy: 0.1)
    XCTAssertEqual(trip.tripGroup.sources.count, 4)
    
    // terminal segments should map trip, but not query
    let startSegment = try XCTUnwrap(trip.segments.first)
    let endSegment = try XCTUnwrap(trip.segments.last)
    let tripStart = try XCTUnwrap(startSegment.start?.coordinate)
    let startDistance = try XCTUnwrap(queryFrom.distance(from: tripStart))
    XCTAssertEqual(startDistance, 350, accuracy: 50)
    let tripEnd = try XCTUnwrap(endSegment.end?.coordinate)
    let endDistance = try XCTUnwrap(queryTo.distance(from: tripEnd))
    XCTAssertEqual(endDistance, 400, accuracy: 50)
    
    // wording should be the 'near' variant
    XCTAssertEqual(startSegment.title, Loc.LeaveNearLocation("Ku-Ring-Gai Chase NSW 2084, Australia"))
    XCTAssertEqual(endSegment.title, Loc.ArriveNearLocation("Brooklyn NSW 2083, Australia"))
    
    // should get the additional start + end annotations
    let startAnnotations = TKUIMapManagerHelper.additionalMapAnnotations(for: startSegment)
    XCTAssertEqual(startAnnotations.count, 1)
    let startAnnotation = try XCTUnwrap(startAnnotations.first)
    let distanceStartAnnotationToQueryFrom = try XCTUnwrap(queryFrom.distance(from: startAnnotation.coordinate))
    XCTAssertEqual(distanceStartAnnotationToQueryFrom, 0, accuracy: 10)
    let endAnnotations = TKUIMapManagerHelper.additionalMapAnnotations(for: endSegment)
    XCTAssertEqual(endAnnotations.count, 1)
    let endAnnotation = try XCTUnwrap(endAnnotations.first)
    let distanceEndAnnotationToQueryTo = try XCTUnwrap(queryTo.distance(from: endAnnotation.coordinate))
    XCTAssertEqual(distanceEndAnnotationToQueryTo, 0, accuracy: 10)

    // Make sure CoreData is happy
    try self.tripKitContext.save()
  }
  
  func testParsingCycleTrainCycleResult() throws {
    let request = try self.request(fromFilename: "routing-cycle-train-cycle")

    XCTAssertNotNil(request)
    XCTAssertEqual(request.tripGroups.count, 5)
    XCTAssertEqual(request.trips.count, 33)

    let cycleGroup = try XCTUnwrap(request.tripGroups.first { $0.trips.contains(where: { $0.usedModeIdentifiers.contains("cy_bic") }) })
    XCTAssertEqual(cycleGroup.sources.count, 3)

    let cycleTrip = try XCTUnwrap(cycleGroup.trips.min { $0.totalScore < $1.totalScore })
    XCTAssertEqual(cycleTrip.segments.count, 9)
    XCTAssertEqual(cycleTrip.segments[0].alerts.count, 0)
    
    // should not get the additional start + end annotations
    let startSegment = try XCTUnwrap(cycleTrip.segments.first)
    let startAnnotations = TKUIMapManagerHelper.additionalMapAnnotations(for: startSegment)
    XCTAssertEqual(startAnnotations.count, 0)
    let endSegment = try XCTUnwrap(cycleTrip.segments.last)
    let endAnnotations = TKUIMapManagerHelper.additionalMapAnnotations(for: endSegment)
    XCTAssertEqual(endAnnotations.count, 0)
    
    // Make sure CoreData is happy
    try self.tripKitContext.save()
  }
  
}
