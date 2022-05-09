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
    XCTAssertEqual(config.distanceUnit, Locale.current.usesMetricSystem ? .metric : .imperial)
    XCTAssertEqual(config.weights, [.money: 1.0, .carbon: 1.0, .time: 1.0, .hassle: 1.0])
    XCTAssertEqual(config.avoidModes, [])
    XCTAssertEqual(config.concession, false)
    XCTAssertEqual(config.wheelchair, false)
    XCTAssertEqual(config.cyclingSpeed, .medium)
    XCTAssertEqual(config.walkingSpeed, .medium)
    XCTAssertNil(config.maximumWalkingMinutes)
    XCTAssertNil(config.minimumTransferMinutes)
    XCTAssertEqual(config.emissions, [:])
    XCTAssertEqual(config.bookingSandbox, false)
    XCTAssertEqual(config.twoWayHireCostIncludesReturn, true)
  }
  
  func testReadPerformance() {
      self.measure {
        _ = TKSettings.Config.userSettings()
      }
  }
    
}
