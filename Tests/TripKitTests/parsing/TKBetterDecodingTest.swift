//
//  TKBetterDecodingTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 18/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import XCTest
@testable import TripKit

class TKBetterDecodingTest: XCTestCase {
  
  struct BillingCycle: Codable {
    @OptionalISO8601OrSecondsSince1970 var toBeAppliedTimestamp: Date?
  }
  
  func testDecodeOptionalISO() throws {
    let json = """
        {
            "paymentTimestamp": "2021-08-07T18:13:54+10:00[Australia/Brisbane]",
        }
        """
    
    let model = try JSONDecoder().decode(BillingCycle.self, from: Data(json.utf8))
    XCTAssertNotNil(model)
    XCTAssertNil(model.toBeAppliedTimestamp)
  }
}
