//
//  TKBuzzInfoProviderTest.swift
//  TripKit
//
//  Created by Adrian Schoenig on 28/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import XCTest

import Marshal

@testable import TripKit

class TKBuzzInfoProviderTest: TKTestCase {
    
  func testRegionInformation() {
    guard
      let json = contentFromJSON(named: "regionInfo-Sydney") as? [String: Any],
      let regions: [RegionInformation] = try? json.value(for: "regions"),
      let sydney = regions.first else { XCTFail(); return }

    XCTAssertEqual(regions.count, 1)
    
    XCTAssertNil(sydney.paratransitInformation)
    XCTAssertEqual(sydney.streetBikePaths, true)
    XCTAssertEqual(sydney.streetWheelchairAccessibility, true)
    XCTAssertEqual(sydney.transitModes.count, 4)
    XCTAssertEqual(sydney.transitBicycleAccessibility, true)
    XCTAssertEqual(sydney.transitConcessionPricing, true)
    XCTAssertEqual(sydney.transitWheelchairAccessibility, true)
  }
  
  // TODO: Add test
//  func testParatransitInformation() {
//  }
  
  func testPublicTransportModes() {
    guard
      let json = contentFromJSON(named: "regionInfo-Sydney") as? [String: Any],
      let regions: [RegionInformation] = try? json.value(for: "regions"),
      let sydney = regions.first else { XCTFail(); return }
    
    XCTAssertEqual(regions.count, 1)
    
    XCTAssertEqual(sydney.transitModes.count, 4)
  }
  
  func testLocationInformationForBikePods() {
    guard
      let json = contentFromJSON(named: "locationInfo-bikePod") as? [String: Any],
      let info = try? LocationInformation(object: json) else { XCTFail(); return }
    
    // Basic info
    XCTAssertEqual(info.what3word, "ruled.item.chart")
    
    // Bike pod info
    XCTAssertNotNil(info.bikePodInfo)
    XCTAssertEqual(info.bikePodInfo?.availableBikes, 9)
    XCTAssertEqual(info.bikePodInfo?.availableSpaces, 1)
    XCTAssertEqual(info.bikePodInfo?.operatorInfo.name, "Melbourne Bike Share")
    XCTAssertNotNil(info.bikePodInfo?.source)
    XCTAssertEqual(info.bikePodInfo?.source?.provider.name, "CityBikes")
  }
  
  // TODO: Add test
//  func testTransitAlerts() {
//  }
}
