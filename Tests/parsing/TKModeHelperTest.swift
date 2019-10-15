//
//  TKModeHelperTest.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 5/1/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import XCTest

@testable import TripKit

class TKModeHelperTest: XCTestCase {
  
  func testSimple() {
    XCTAssertEqual(true,  TKModeHelper.modesContain(["wa_wal", "me_car"], ["wa_wal"]))
    XCTAssertEqual(false, TKModeHelper.modesContain(["wa_wal", "me_car"], ["pt_pub"]))
    XCTAssertEqual(true,  TKModeHelper.modesContain(["wa_wal"], ["wa_wal", "me_car"]))
    XCTAssertEqual(false, TKModeHelper.modesContain(["wa_wal"], ["pt_pub", "me_car"]))
  }
  
  func testEmpty() {
    XCTAssertEqual(false, TKModeHelper.modesContain([], ["wa_wal"]))
    XCTAssertEqual(false, TKModeHelper.modesContain(["wa_wal"], []))
    XCTAssertEqual(false, TKModeHelper.modesContain([], []))
  }
  
  func testSubmodes() {
    XCTAssertEqual(false, TKModeHelper.modesContain(["cy_bic-s_melb"], ["cy_bic-s"]))
    XCTAssertEqual(true,  TKModeHelper.modesContain(["cy_bic-s"], ["cy_bic-s_melb"]))
    XCTAssertEqual(false, TKModeHelper.modesContain(["cy_bic"],   ["cy_bic-s_melb"]))
    XCTAssertEqual(true,  TKModeHelper.modesContain(["me_car-s"], ["me_car-s_GOG"]))
    XCTAssertEqual(false, TKModeHelper.modesContain(["me_car"],   ["me_car-s"]))
  }
  
}
