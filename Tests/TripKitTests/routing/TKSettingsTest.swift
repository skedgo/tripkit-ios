//
//  TKSettingsTest.swift
//  TripKitTests
//
//  Created by Adrian Schoenig on 16.10.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import XCTest

@testable import TripKit

class TKSettingsTest: XCTestCase {
  
  func testDefaultValues() throws {
    let config = TKSettings.Config.defaultValues()
    XCTAssertEqual(config.version, TKSettings.parserJsonVersion)
    XCTAssertEqual(config.distanceUnit, .auto)
    XCTAssertEqual(config.weights, .init(money: 1.0, carbon: 1.0, time: 1.0, hassle: 1.0, exercise: 1.0))
    XCTAssertEqual(config.avoidModes, [])
    XCTAssertEqual(config.concession, false)
    XCTAssertEqual(config.wheelchair, false)
    XCTAssertEqual(config.cyclingSpeed, .medium)
    XCTAssertEqual(config.walkingSpeed, .medium)
    XCTAssertNil(config.maximumWalkingMinutes)
    XCTAssertNil(config.minimumTransferMinutes)
    XCTAssertEqual(config.emissions, [:])
    XCTAssertEqual(config.bookingSandbox, false)
    XCTAssertEqual(config.twoWayHireCostIncludesReturn, false)
  }
  
  func testRoundtripCoding() throws {
    let config = TKSettings.Config.defaultValues()
    let encoded = try JSONEncoder().encode(config)
    let restored = try JSONDecoder().decode(TKSettings.Config.self, from: encoded)
    XCTAssertEqual(config, restored)
  }
  
  func testWeightsToJSON() throws {
    let config = TKSettings.Config.defaultValues()
    
    let encoded = try JSONEncoder().encode(config)
    let restored = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    XCTAssertEqual(restored["weights"] as? [String: AnyHashable], [
      "money": 1.0,
      "carbon": 1.0,
      "time": 1.0,
      "hassle": 1.0,
      "exercise": 1.0
    ] as [String: AnyHashable])
  }
  
  func testSpeed() throws {
    XCTAssertEqual(TKSettings.Speed(apiValue: -1), .impaired)
    XCTAssertEqual(TKSettings.Speed(apiValue: 0), .slow)
    XCTAssertEqual(TKSettings.Speed(apiValue: 1), .medium)
    XCTAssertEqual(TKSettings.Speed(apiValue: 2), .fast)

    XCTAssertEqual(TKSettings.Speed(apiValue: "4mps"), .custom(4))
  }
  
  func testReadPerformance() {
    self.measure {
      _ = TKSettings.Config.userSettings()
    }
  }
    
}
