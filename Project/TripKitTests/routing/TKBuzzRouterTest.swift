//
//  TKBuzzRouterTest.swift
//  TripKitTests
//
//  Created by Adrian Schoenig on 24.09.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

import XCTest

@testable import TripKit

class TKBuzzRouterTest: TKTestCase {

  func testParsingOldPTResult() throws {
    let parser = TKRoutingParser(tripKitContext: tripKitContext)
    
    let expectation = self.expectation(description: "Parser finished")
    
    let json = try contentFromJSON(named: "routing-pt-oldish") as! [String: Any]
    parser.parseAndAddResult(json) { request in
      
      // Evaluating the returned response
      XCTAssertNotNil(request)
      XCTAssertEqual(request?.tripGroups?.count, 3)
      XCTAssertEqual(request?.trips.count, 4 + 4 + 4)
      for trip in request?.trips ?? [] {
        XCTAssertGreaterThan(trip.segments().count, 0)
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
  
  func testParsingGoGetResult() throws {
    let parser = TKRoutingParser(tripKitContext: tripKitContext)
    
    let expectation = self.expectation(description: "Parser finished")
    
    let json = try contentFromJSON(named: "routing-goget") as! [String: Any]
    parser.parseAndAddResult(json) { request in
      
      XCTAssertNotNil(request)
      XCTAssertEqual(request?.tripGroups?.count, 1)
      XCTAssertEqual(request?.tripGroups?.first?.sources.count, 3)
      XCTAssertEqual(request?.trips.count, 1)
      
      let trip = request?.trips.first
      XCTAssertEqual(trip?.segments().count, 5)
      
      XCTAssertNil(trip?.segments()[1].bookingInternalURL())
      XCTAssertNotNil(trip?.segments()[1].bookingExternalActions())
      
      XCTAssertEqual(trip?.segments()[2].alerts().count, 4)
      XCTAssertEqual(trip?.segments()[2].alertsWithAction().count, 0)
      XCTAssertEqual(trip?.segments()[2].alertsWithContent().count, 4)
      XCTAssertEqual(trip?.segments()[2].alertsWithLocation().count, 4)
      XCTAssertEqual(trip?.segments()[2].timesAreRealTime(), true)
      XCTAssertEqual(trip?.segments()[2].isSharedVehicle(), true)

      XCTAssertEqual(trip?.segments()[3].hasCarParks(), true)

      // Make sure CoreData is happy
      try! self.tripKitContext.save()
      
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 3) { error in
      XCTAssertNil(error)
    }
  }
  
  func testParsingPerformance() throws {
    let parser = TKRoutingParser(tripKitContext: tripKitContext)
    let json = try contentFromJSON(named: "routing-pt-oldish") as! [String: Any]
    measure {
      let request = parser.parseAndAddResultBlocking(json)
      XCTAssertNotNil(request)
    }
  }
  
  func testTripCache() throws {
    let identifier = "Test"
    let directory = TKJSONCacheDirectory.documents // where TKBuzzRouter keeps its trips
    let json = try contentFromJSON(named: "routing-pt-oldish") as! [String: Any]

    // 0. Clear
    TKJSONCache.remove(identifier, directory: directory)
    XCTAssertNil(TKJSONCache.read(identifier, directory: directory))
    
    // 1. Save the trip to the cache
    TKJSONCache.save(identifier, dictionary: json, directory: directory)
    XCTAssertNotNil(TKJSONCache.read(identifier, directory: directory))
    
    // 2. Retrieve from cache
    let expectation = self.expectation(description: "Trip downloaded from cache")
    let router = TKBuzzRouter()
    router.downloadTrip(URL(string: "http://example.com/")!, identifier: identifier, intoTripKitContext: self.tripKitContext) { trip in
      XCTAssertNotNil(trip)
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 5) { error in
      XCTAssertNil(error)
    }
  }
  
}

