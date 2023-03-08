//
//  TKRouterTest.swift
//  TripKitTests
//
//  Created by Adrian Schoenig on 24.09.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData

import XCTest

@testable import TripKit

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
    let request = try self.request(fromFilename: "routing-pt-oldish")
    
    // Evaluating the returned response
    XCTAssertEqual(request.tripGroups.count, 3)
    XCTAssertEqual(request.trips.count, 4 + 4 + 4)
    for trip in request.trips {
      XCTAssertGreaterThan(trip.segments.count, 0)
    }
    
    // Evaluating what's in Core Data
    XCTAssertEqual(self.tripKitContext.fetchObjects(TripGroup.self).count, 3)
    XCTAssertEqual(self.tripKitContext.fetchObjects(Trip.self).count, 4 + 4 + 4)
    XCTAssertEqual(self.tripKitContext.fetchObjects(SegmentTemplate.self).count, 20, "Each segment that's not hidden should be parsed and added just once.")
    
    // Make sure CoreData is happy
    try self.tripKitContext.save()
  }
  
  func testParsingPerformance() throws {
    let data = try dataFromJSON(named: "routing-pt-oldish")
    let response = try JSONDecoder().decode(TKAPI.RoutingResponse.self, from: data)
    measure {
      do {
        let request = try TKRoutingParser.addBlocking(response, into: self.tripKitContext)
        XCTAssertNotNil(request)
      } catch {
        XCTFail("Parsing failed with \(error)")
      }
    }
  }
  
  func testParsingGoGetResult() throws {
    let request = try self.request(fromFilename: "routing-goget")

    XCTAssertNotNil(request)
    XCTAssertEqual(request.tripGroups.count, 1)
    XCTAssertEqual(request.tripGroups.first?.sources.count, 3)
    XCTAssertEqual(request.trips.count, 1)
    
    let trip = try XCTUnwrap(request.trips.first)
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
    
    // Make sure CoreData is happy
    try self.tripKitContext.save()
  }
  
  func testParsingPublicTransportWithStops() throws {
    let request = try self.request(fromFilename: "routing-with-stops")

    XCTAssertNotNil(request)
    XCTAssertEqual(request.tripGroups.count, 1)
    XCTAssertEqual(request.trips.count, 16)
    
    for trip in request.trips {
      let services = trip.segments.compactMap(\.service)
      XCTAssertEqual(services.count, 1)
      for service in services {
        XCTAssertTrue(service.hasServiceData)
        XCTAssertEqual(service.shape?.routeIsTravelled, true)
        
        for visit in service.visits ?? [] {
          XCTAssertNotNil(visit.departure ?? visit.arrival, "No time for visit to stop \(visit.stop.stopCode) - service \(service.code)")
        }
      }
    }
    
    if let best = request.tripGroups.first?.visibleTrip, let bestService = best.segments[2].service {
      XCTAssertEqual(best.totalScore, 29.8, accuracy: 0.1)
      XCTAssertEqual(bestService.code, "847016")
      
      XCTAssertEqual(bestService.visits?.count, 27)
      XCTAssertEqual(bestService.sortedVisits.count, 27)
      XCTAssertEqual(bestService.sortedVisits.map { $0.index }, (0...26).map { $0 })
      
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
    try self.tripKitContext.save()
  }
  
  func testParsingRouteGetsWalks() throws {
    let request = try self.request(fromFilename: "routing-walk")

    XCTAssertNotNil(request)
    XCTAssertEqual(request.tripGroups.count, 1)
    XCTAssertEqual(request.trips.count, 1)

    let walkGroup = try XCTUnwrap(request.tripGroups.first)
    let walkTrip = try XCTUnwrap(walkGroup.trips.first)
    XCTAssertEqual(walkTrip.segments.count, 3)
    XCTAssertNotNil(walkTrip.segments[1].shapes)
    XCTAssertEqual(walkTrip.segments[1].shapes.count, 4)
    
    // Make sure CoreData is happy
    try self.tripKitContext.save()
  }
  
  func testParsingTripWithSharedScooter() throws {
    let request = try self.request(fromFilename: "routing-scooter-vehicle")

    XCTAssertNotNil(request)
    XCTAssertEqual(request.tripGroups.count, 1)
    XCTAssertEqual(request.trips.count, 2)

    let sharedSegments = request.trips.flatMap(\.segments).filter(\.isSharedVehicle).filter(\.isStationary)
    XCTAssertEqual(sharedSegments.count, 2)
    
    for segment in sharedSegments {
      XCTAssertNotNil(segment.sharedVehicle)
    }
    
    // Make sure CoreData is happy
    try self.tripKitContext.save()
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
    TKTripFetcher.downloadTrip(URL(string: "http://example.com/")!, identifier: identifier, into: self.tripKitContext) { trip in
      XCTAssertNotNil(trip)
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 5) { error in
      XCTAssertNil(error)
    }
  }
  
  func testURLWithAdditionalParameterArray() {
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    
    let request = TKRouter.RoutingQuery(
      from: TKNamedCoordinate(coordinate: .init(latitude: -31.8875, longitude: 115.9443)),
      to: TKNamedCoordinate(coordinate: .init(latitude: -31.8408, longitude: 115.92)),
      modes: ["me_car"],
      additional: [
        .init(name: "neverAllowModes", value: "wa_wal"),
        .init(name: "neverAllowModes", value: "me_mot"),
      ],
      context: context
    )
    
    let paras = TKRouter.requestParameters(for: request, modeIdentifiers: nil, additional: nil, config: nil)
    // Make sure this doesn't end up as a `[String?]` or `[String?]?`
    XCTAssertEqual((paras["neverAllowModes"] as? [String]?)??.sorted(), ["me_mot", "wa_wal"].sorted())
  }
  
}

