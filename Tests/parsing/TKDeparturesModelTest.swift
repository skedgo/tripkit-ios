//
//  TKDeparturesModelTest.swift
//  TripKitTests
//
//  Created by Adrian Schoenig on 22.09.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import XCTest

@testable import TripKit


class TKDeparturesModelTest: XCTestCase {
  
  func testParsingParentStopDepartures() throws {
    let decoder = JSONDecoder()
    let data = try self.dataFromJSON(named: "departures-parentStop")
    let departures = try decoder.decode(TKAPI.Departures.self, from: data)

    XCTAssertNotNil(departures)
  }

}
