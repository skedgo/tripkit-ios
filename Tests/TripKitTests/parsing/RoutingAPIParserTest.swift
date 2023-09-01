//
//  RoutingAPIParserTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 9/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import XCTest
@testable import TripKit

class RoutingAPIParserTest: XCTestCase {
  
  func testExampleRoutingResponses() {
    let knownToWork = [
      "routing-bus+scooter",
      "routing-cycle-train-cycle",
      "routing-drive-park-walk-train",
      "routing-goget-park",
      "routing-goget",
      "routing-motorbike",
      "routing-pt-cancelled",
      "routing-pt-continuation",
      "routing-pt-impossible",
      "routing-pt-oldish",
      "routing-pt-platforms",
      "routing-pt-realtime",
      "routing-pt-wheelchair-reroute",
      "routing-scooters",
      "routing-walk",
      "routing-with-stops",
    ]
    
    for name in knownToWork {
      XCTAssertNoThrow(try {
        let data = try dataFromJSON(named: name)
        let parsed = try JSONDecoder().decode(TKAPI.RoutingResponse.self, from: data)
        XCTAssertNil(parsed.error)
        
        XCTAssertNotNil(parsed.groups, "Didn't get groups for \(name)")
        XCTAssertNotNil(parsed.segmentTemplates, "Didn't get templates for \(name)")

        let groups = parsed.groups ?? []
        let templates = parsed.segmentTemplates ?? []
        XCTAssertFalse(groups.isEmpty, "Got empty groups for \(name)")
        XCTAssertFalse(templates.isEmpty, "Got empty templates for \(name)")
        
        for trip in groups.flatMap(\.trips) {
          XCTAssertTrue(trip.depart.timeIntervalSinceNow < 30 * 24 * 60 * 60, "Bad departure for trip in \(name)")
          XCTAssertTrue(trip.arrive.timeIntervalSinceNow < 30 * 24 * 60 * 60, "Bad arrival for trip in \(name)")
        }
        
      }(), "Parsing failed for \(name)")
    }
  }
  
  func testWalkingShapes() throws {
    let data = try dataFromJSON(named: "routing-walk")
    let parsed = try JSONDecoder().decode(TKAPI.RoutingResponse.self, from: data)
    let template = try XCTUnwrap(parsed.segmentTemplates?.first)
    
    XCTAssertEqual(template.streets?.count, 4)
  }
  
  func testKnownInstruction() throws {
    let input = """
      {
        "encodedWaypoints": "...",
        "instruction": "TURN_SLIGHTLY_LEFT"
      }
      """
    
    let shape = try JSONDecoder().decode(TKAPI.SegmentShape.self, from: Data(input.utf8))
    XCTAssertEqual(shape.encodedWaypoints, "...")
    XCTAssertTrue(shape.travelled)
    XCTAssertEqual(shape.instruction, .turnSlightyLeft)
  }
  
  func testUnknownInstruction() throws {
    let input = """
      {
        "encodedWaypoints": "...",
        "instruction": "WHEELIE_ALONG"
      }
      """
    
    let shape = try JSONDecoder().decode(TKAPI.SegmentShape.self, from: Data(input.utf8))
    XCTAssertEqual(shape.encodedWaypoints, "...")
    XCTAssertNil(shape.instruction)
  }
  
  func testUnknownRoadTags() throws {
    let input = """
      {
        "encodedWaypoints": "...",
        "roadTags": [
          "CYCLE-LANE",
          "CYCLE-TRACK",
          "CYCLE-NETWORK",
          "BICYCLE-DESIGNATED",
          "BICYCLE-BOULEVARD",
          "SIDE-WALK",
          "MAIN-ROAD",
          "SIDE-ROAD",
          "SHARED-ROAD",
          "UNPAVED/UNSEALED"
        ]
      }
      """
    
    let shape = try JSONDecoder().decode(TKAPI.SegmentShape.self, from: Data(input.utf8))
    XCTAssertEqual(shape.encodedWaypoints, "...")
    XCTAssertEqual(shape.roadTags, [.cycleLane,
                                    .cycleTrack,
                                    .cycleNetwork,
                                    .bicycleDesignated,
                                    .bicycleBoulevard,
                                    .sideWalk,
                                    .mainRoad,
                                    .sideRoad,
                                    .sharedRoad])
  }
  
  func testMissingRoadTags() throws {
    let input = """
      {
        "encodedWaypoints": "..."
      }
      """
    
    let shape = try JSONDecoder().decode(TKAPI.SegmentShape.self, from: Data(input.utf8))
    XCTAssertEqual(shape.encodedWaypoints, "...")
    XCTAssertEqual(shape.roadTags, [])
  }
  
}
