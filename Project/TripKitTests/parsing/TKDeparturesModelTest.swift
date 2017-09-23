//
//  TKDeparturesModelTest.swift
//  TripKitTests
//
//  Created by Adrian Schoenig on 22.09.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import XCTest

@testable import TripKit


class TKDeparturesModelTest: TKTestCase {
  
  
  func testParsingParentStopDepartures() {
    let data = self.dataFromJSON(named: "departures-parentStop")!
    let decoder = JSONDecoder()
    
    do {
      let departures = try decoder.decode(API.Departures.self, from: data)
      XCTAssertNotNil(departures)
    
    } catch {
      XCTFail("Conversion failed with \(error)")
    }
  }

}
