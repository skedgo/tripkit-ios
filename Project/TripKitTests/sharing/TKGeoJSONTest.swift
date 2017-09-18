//
//  TKGeoJSONTest.swift
//  TripKitTests
//
//  Created by Adrian Schoenig on 12.09.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import XCTest

@testable import TripKit

class TKGeoJSONTest: TKTestCase {
  
  
  func testParsing() {
    
    let data = self.dataFromJSON(named: "geojson-nuremberg")!
    let decoder = JSONDecoder()
    do {
      let nuremberg = try decoder.decode(TKGeoJSON.self, from: data)
      XCTAssertNotNil(nuremberg)
      
      if case .collection(let features) = nuremberg {
        XCTAssertEqual(10, features.count)
        
        for feature in features {
          XCTAssertNotNil(feature.properties, "Missing properties for \(feature.geometry)")
          XCTAssert(feature.properties is TKMapZenProperties)
        }
        
      } else {
        XCTFail("Didn't capture collection")
      }
      
    } catch {
      XCTFail("Conversion failed with \(error)")
    }
  }
  
}
