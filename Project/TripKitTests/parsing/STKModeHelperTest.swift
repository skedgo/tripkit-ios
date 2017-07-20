//
//  STKModeHelperTest.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 5/1/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import XCTest

@testable import TripKit

class STKModeHelperTest: XCTestCase {
  
  func testSimple() {
    XCTAssertEqual(true,  STKModeHelper.modesContain(["wa_wal", "me_car"], ["wa_wal"]))
    XCTAssertEqual(false, STKModeHelper.modesContain(["wa_wal", "me_car"], ["pt_pub"]))
    XCTAssertEqual(true,  STKModeHelper.modesContain(["wa_wal"], ["wa_wal", "me_car"]))
    XCTAssertEqual(false, STKModeHelper.modesContain(["wa_wal"], ["pt_pub", "me_car"]))
  }
  
  func testEmpty() {
    XCTAssertEqual(false, STKModeHelper.modesContain([], ["wa_wal"]))
    XCTAssertEqual(false, STKModeHelper.modesContain(["wa_wal"], []))
    XCTAssertEqual(false, STKModeHelper.modesContain([], []))
  }
  
  func testSubmodes() {
    XCTAssertEqual(false, STKModeHelper.modesContain(["cy_bic-s_melb"], ["cy_bic-s"]))
    XCTAssertEqual(true,  STKModeHelper.modesContain(["cy_bic-s"], ["cy_bic-s_melb"]))
    XCTAssertEqual(false, STKModeHelper.modesContain(["cy_bic"],   ["cy_bic-s_melb"]))
    XCTAssertEqual(true,  STKModeHelper.modesContain(["me_car-s"], ["me_car-s_GOG"]))
    XCTAssertEqual(false, STKModeHelper.modesContain(["me_car"],   ["me_car-s"]))
  }
  
}
