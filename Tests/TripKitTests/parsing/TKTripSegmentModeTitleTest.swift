//
//  TKTripSegmentModeTitleTest.swift
//  TripKitTests
//
//  Created by Brian Huang on 27/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import XCTest
@testable import TripKit

class TKTripSegmentModeTitleTest: XCTestCase {
  
  func testSegmentModeTitle() throws {
    let json = """
      {
          "alt": "Shuttle",
          "color": {
              "blue": 26,
              "green": 34,
              "red": 226
          },
          "description": "SMARTBus",
          "identifier": "ps_drt_smartbus",
          "localIcon": "shuttlebus",
          "remoteIconIsBranding": true
      }
      """
    
    let model = try JSONDecoder().decode(TKModeInfo.self, from: Data(json.utf8))
    XCTAssertNotNil(model)
    XCTAssertEqual(model.descriptor, "SMARTBus")
  }
  
}
