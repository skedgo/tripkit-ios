//
//  TKRegionManagerTest.swift
//  TripKitTests
//
//  Created by Adrian Schoenig on 26.09.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import XCTest

@testable import TripKit

class TKRegionManagerTest: XCTestCase {
  
  var regionData: Data! = nil
  
  override func setUp() {
    super.setUp()
    
    regionData = try! dataFromJSON(named: "regions")
    TKRegionManager.shared.updateRegions(from: regionData)
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testParsing() {
    XCTAssert(TKRegionManager.shared.hasRegions)
    XCTAssertEqual(TKRegionManager.shared.regions.count, 143)
  }
  
  func testSavingToCache() throws {
    // First read the good data
    let data = TKRegionManager.readLocalCache()
    XCTAssertNotNil(data)
    
    // Then save empty regions data
    let rubbish = try JSONDecoder().decode(RegionsResponse.self, withJSONObject: [
      "regions": [],
      "modes": [:],
      "hashCode": 0
      ])
    let rubbishData = try JSONEncoder().encode(rubbish)
    TKRegionManager.shared.updateRegions(from: rubbishData)
    TKRegionManager.saveToCache(rubbishData)
    XCTAssert(TKRegionManager.shared.hasRegions)
    XCTAssertEqual(TKRegionManager.shared.regions.count, 0)

    // Then read the good data in again
    TKRegionManager.shared.updateRegions(from: data!)
    XCTAssert(TKRegionManager.shared.hasRegions)
    XCTAssertEqual(TKRegionManager.shared.regions.count, 143)

  }
  
}
