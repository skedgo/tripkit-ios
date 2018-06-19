//
//  TKJSONSanitizerTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 03.11.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import XCTest

@testable import TripKit

class TKJSONSanitizerTest: XCTestCase {

  private struct TestStruct: Codable {
    let color: API.RGBColor
    let url: String
    let derp: Int?
    let number: Double
  }
  
  func testMadeUpExample() {
    let nonJson: [[String: Any]] = [[
      "color": #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
      "url": URL(string: "https://api.tripgo.com")!,
      "derp": NSNull(),
      "number": NSNumber(value: 1),
    ]]

    guard let sanitized = TKJSONSanitizer.sanitize(nonJson) else { XCTFail(); return }
    let decoded = try? JSONDecoder().decode([TestStruct].self, withJSONObject: sanitized)
    XCTAssertNotNil(decoded)
  }
  
  func testModeInfo() {
    let nonJson: [String: Any] = [
      "color": #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
      "alt": "Test",
    ]
    
    guard let sanitized = TKJSONSanitizer.sanitize(nonJson) else { XCTFail(); return }
    let decoded = try? JSONDecoder().decode(ModeInfo.self, withJSONObject: sanitized)
    XCTAssertNotNil(decoded)
  }
    
}
