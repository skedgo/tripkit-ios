//
//  TKRouterTest.swift
//  TripKitTests
//
//  Created by Adrian Schoenig on 24.09.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

import XCTest

@testable import TripKit
@testable import TripKitUI

class TKRouterTest: TKTestCase {

  override func setUpWithError() throws {
    try super.setUpWithError()
    
    let env = ProcessInfo.processInfo.environment
    if let apiKey = env["TRIPGO_API_KEY"], !apiKey.isEmpty {
      TripKit.apiKey = apiKey
    } else {
      try XCTSkipIf(true, "No TripGo API key supplied")
    }
  }
  
  func testParsingOldPTResult() throws {
    let parser = TKRoutingParser(tripKitContext: tripKitContext)
    
    let expectation = self.expectation(description: "Parser finished")
    
    let json: [String: Any] = try contentFromJSON(named: "routing-pt-oldish")
    parser.parseAndAddResult(json) { request in
      
      // Evaluating the returned response
      XCTAssertNotNil(request)
      XCTAssertEqual(request?.tripGroups?.count, 3)
      XCTAssertEqual(request?.trips.count, 4 + 4 + 4)
      for trip in request?.trips ?? [] {
        XCTAssertGreaterThan(trip.segments.count, 0)
      }
      
      // Evaluating what's in Core Data
      XCTAssertEqual(self.tripKitContext.fetchObjects(TripGroup.self).count, 3)
      XCTAssertEqual(self.tripKitContext.fetchObjects(Trip.self).count, 4 + 4 + 4)
      XCTAssertEqual(self.tripKitContext.fetchObjects(SegmentTemplate.self).count, 20, "Each segment that's not hidden should be parsed and added just once.")
      
      // Make sure CoreData is happy
      try! self.tripKitContext.save()
      
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 5) { error in
      XCTAssertNil(error)
    }
  }
  
  func testParsingPerformance() throws {
    let parser = TKRoutingParser(tripKitContext: tripKitContext)
    let json: [String: Any] = try contentFromJSON(named: "routing-pt-oldish")
    measure {
      let request = parser.parseAndAddResultBlocking(json)
      XCTAssertNotNil(request)
    }
  }
  
  func testParsingGoGetResult() throws {
    let parser = TKRoutingParser(tripKitContext: tripKitContext)
    
    let expectation = self.expectation(description: "Parser finished")
    
    let json: [String: Any] = try contentFromJSON(named: "routing-goget")
    parser.parseAndAddResult(json) { request in
      
      do {
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.tripGroups?.count, 1)
        XCTAssertEqual(request?.tripGroups?.first?.sources.count, 3)
        XCTAssertEqual(request?.trips.count, 1)
        
        let trip = try XCTUnwrap(request?.trips.first)
        XCTAssertEqual(trip.segments.count, 5)
        
        
        XCTAssertNil(trip.segments[1].bookingInternalURL)
        XCTAssertNotNil(trip.segments[1].bookingExternalActions)
        
        XCTAssertEqual(trip.segments[2].alerts.count, 4)
        XCTAssertEqual(trip.segments[2].alertsWithAction.count, 0)
        XCTAssertEqual(trip.segments[2].alertsWithContent.count, 4)
        XCTAssertEqual(trip.segments[2].alertsWithLocation.count, 4)
        XCTAssertEqual(trip.segments[2].timesAreRealTime, true)
        XCTAssertEqual(trip.segments[2].isSharedVehicle, true)

        XCTAssertEqual(trip.segments[3].hasCarParks, true)
        
        // wording should be the regular variant (not 'near')
        let startSegment = try XCTUnwrap(trip.segments.first)
        let endSegment = try XCTUnwrap(trip.segments.last)
        XCTAssertEqual(startSegment.title, Loc.LeaveFromLocation("Mount Street & Little Walker Street"))
        XCTAssertEqual(endSegment.title, Loc.ArriveAtLocation("2A Bligh Street, 2000 Sydney, Australia"))

        // Make sure CoreData is happy
        try self.tripKitContext.save()
        
      } catch {
        XCTFail("Unexpected error: \(error)")
      }
        
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 3) { error in
      XCTAssertNil(error)
    }
  }
  
  func testParsingCycleTrainCycleResult() throws {
    let parser = TKRoutingParser(tripKitContext: tripKitContext)
    
    let expectation = self.expectation(description: "Parser finished")
    
    let json: [String: Any] = try contentFromJSON(named: "routing-cycle-train-cycle")
    parser.parseAndAddResult(json) { request in
      // TODO: (in another test): check the waypoint issue
      
      do {
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.tripGroups?.count, 5)
        XCTAssertEqual(request?.trips.count, 33)

        let cycleGroup = try XCTUnwrap(request?.tripGroups?.first { $0.trips.contains(where: { $0.usedModeIdentifiers().contains("cy_bic") }) })
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
        
      } catch {
        XCTFail("Unexpected error: \(error)")
      }
      
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 3) { error in
      XCTAssertNil(error)
    }
  }
  
  func testParsingPublicTransportWithStops() throws {
    let parser = TKRoutingParser(tripKitContext: tripKitContext)
    
    let expectation = self.expectation(description: "Parser finished")
    
    let json: [String: Any] = try contentFromJSON(named: "routing-with-stops")
    parser.parseAndAddResult(json) { request in
      XCTAssertNotNil(request)
      XCTAssertEqual(request?.tripGroups?.count, 1)
      XCTAssertEqual(request?.trips.count, 16)
      
      for trip in request?.trips ?? [] {
        let services = trip.segments.compactMap { $0.service }
        XCTAssertEqual(services.count, 1)
        for service in services {
          XCTAssertTrue(service.hasServiceData)
          XCTAssertEqual(service.shape?.routeIsTravelled, true)
          
          for visit in service.visits ?? [] {
            XCTAssertNotNil(visit.departure ?? visit.arrival, "No time for visit to stop \(visit.stop.stopCode) - service \(service.code)")
          }
        }
      }
      
      if let best = request?.tripGroups?.first?.visibleTrip, let bestService = best.segments[2].service {
        XCTAssertEqual(best.totalScore, 29.8, accuracy: 0.1)
        XCTAssertEqual(bestService.code, "847016")
        
        XCTAssertEqual(bestService.visits?.count, 27)
        XCTAssertEqual(bestService.sortedVisits.count, 27)
        XCTAssertEqual(bestService.sortedVisits.map { $0.index.intValue }, (0...26).map { $0 })
        
        XCTAssertEqual(bestService.sortedVisits.map { $0.stop.stopCode },
                       ["202634",
                        "202635",
                        "202637",
                        "202653",
                        "202654",
                        "202656",
                        "202659",
                        "202661",
                        "202663",
                        "202255",
                        "202257",
                        "202268",
                        "202281",
                        "202258",
                        "202260",
                        "202151",
                        "202152",
                        "202153",
                        "202155",
                        "201060",
                        "201051",
                        "201056",
                        "200055",
                        "200057",
                        "2000421",
                        "200059",
                        "200065",
          ])
      } else {
        XCTFail("Couldn't find best trip")
      }
      
      // Make sure CoreData is happy
      try! self.tripKitContext.save()
      
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 3) { error in
      XCTAssertNil(error)
    }
  }
  
  func testParsingTripAwayFromNetwork11833() throws {
    let parser = TKRoutingParser(tripKitContext: tripKitContext)
    
    let expectation = self.expectation(description: "Parser finished")
    
    let json: [String: Any] = try contentFromJSON(named: "routing-motorbike")
    parser.parseAndAddResult(json) { request in
      do {
        XCTAssertNotNil(request)
        let queryFrom = try XCTUnwrap(request?.fromLocation.coordinate)
        let queryTo = try XCTUnwrap(request?.toLocation.coordinate)

        // reconstructing the query
        let expectedFrom = CLLocationCoordinate2D(latitude: -33.6594, longitude: 151.2237)
        let queryFromDistance = try XCTUnwrap(queryFrom.distance(from: expectedFrom))
        XCTAssertEqual(queryFromDistance, 0, accuracy: 10)
        let expectedTo = CLLocationCoordinate2D(latitude: -33.54381, longitude: 151.21246)
        let queryToDistance = try XCTUnwrap(queryTo.distance(from: expectedTo))
        XCTAssertEqual(queryToDistance, 0, accuracy: 10)

        // basic trip properties
        XCTAssertEqual(request?.tripGroups?.count, 1)
        XCTAssertEqual(request?.trips.count, 1)
        let trip = try XCTUnwrap(request?.trips.first)
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
      
      } catch {
        XCTFail("Unexpected error: \(error)")
      }
      
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 3) { error in
      XCTAssertNil(error)
    }
  }
  
  func testTripCache() throws {
    let identifier = "Test"
    let directory = TKFileCacheDirectory.documents // where TKRouter keeps its trips
    let json: [String: Any] = try contentFromJSON(named: "routing-pt-oldish")

    // 0. Clear
    TKJSONCache.remove(identifier, directory: directory)
    XCTAssertNil(TKJSONCache.read(identifier, directory: directory))
    
    // 1. Save the trip to the cache
    TKJSONCache.save(identifier, dictionary: json, directory: directory)
    XCTAssertNotNil(TKJSONCache.read(identifier, directory: directory))
    
    // 2. Retrieve from cache
    let expectation = self.expectation(description: "Trip downloaded from cache")
    let router = TKRouter()
    router.downloadTrip(URL(string: "http://example.com/")!, identifier: identifier, intoTripKitContext: self.tripKitContext) { trip in
      XCTAssertNotNil(trip)
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 5) { error in
      XCTAssertNil(error)
    }
  }
  
}

