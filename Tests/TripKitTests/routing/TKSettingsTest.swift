//
//  TKSettingsTest.swift
//  TripKitTests
//
//  Created by Adrian Schoenig on 16.10.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import XCTest

@testable import TripKit

#if SWIFT_PACKAGE
import TripKitObjc
#endif

class TKSettingsTest: XCTestCase {
  
  override func setUp() {
    // TODO: Should reset here ideally
  }
  
  func testDefaultValues() throws {
    // TODO: Renable when settings are settable to defaults
    try XCTSkipIf(true)
    
    let config = TKSettings.Config()
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
        _ = TKSettings.Config()
      }
  }
    
}
