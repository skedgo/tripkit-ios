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
  
  override func setUp() async throws {
    try await super.setUp()
    
    regionData = try dataFromJSON(named: "regions")
    let response = try JSONDecoder().decode(TKAPI.RegionsResponse.self, from: regionData)
    await TKRegionManager.shared.updateRegions(from: response)
  }
  
  override func tearDown() {
    regionData = nil
    super.tearDown()
  }
  
  func testParsing() {
    XCTAssert(TKRegionManager.shared.hasRegions)
    XCTAssertEqual(TKRegionManager.shared.regions.count, 195)
  }
  
  func testSavingToCache() async throws {
    // First read the good data
    let data = TKRegionManager.readLocalCache()
    XCTAssertNotNil(data)
    
    // Then save empty regions data
    let rubbish = try JSONDecoder().decode(TKAPI.RegionsResponse.self, withJSONObject: [
      "regions": [AnyHashable](),
      "modes": [String: AnyHashable](),
      "hashCode": 0
    ] as [String : Any])
    let rubbishData = try JSONEncoder().encode(rubbish)
    await TKRegionManager.shared.updateRegions(from: rubbish)
    TKRegionManager.saveToCache(rubbishData)
    XCTAssert(TKRegionManager.shared.hasRegions)
    XCTAssertEqual(TKRegionManager.shared.regions.count, 0)

    // Then read the good data in again
    let cachedResponse = try JSONDecoder().decode(TKAPI.RegionsResponse.self, from: regionData)
    await TKRegionManager.shared.updateRegions(from: cachedResponse)
    XCTAssert(TKRegionManager.shared.hasRegions)
    XCTAssertEqual(TKRegionManager.shared.regions.count, 195)
  }
  
  func testSortingModes() throws {
    let group1 = [
      "in_air",
      "pt_pub",
      "pt_ltd_SCHOOLBUS",
      "ps_tax",
      "me_car",
      "me_car-r_SwiftFleet",
      "me_mot",
      "cy_bic",
      "cy_bic-s_bysykkelen",
      "wa_wal"
    ]
    
    let group2 = [
      "in_air",
      "pt_pub",
      "pt_ltd_SCHOOLBUS",
      "ps_tax",
      "ps_tnc_UBER",
      "me_car",
      "me_car-r_SwiftFleet",
      "me_mot",
      "cy_bic",
      "cy_bic-s",
      "wa_wal"
    ]
    
    let group3 = [
      "pt_pub",
      "me_car",
      "me_mot"
    ]
    
    func toRoutingModes(_ identifiers: [String]) -> [TKRegion.RoutingMode] {
      identifiers.map(TKRegion.RoutingMode.buildForTesting)
    }
    
    let sorted = TKRegionManager.sortedFlattenedModes([toRoutingModes(group1), toRoutingModes(group2), toRoutingModes(group3)]).map { $0.identifier }
    
    XCTAssertEqual(sorted, [
      "in_air",
      "pt_pub",
      "pt_ltd_SCHOOLBUS",
      "ps_tax",
      "ps_tnc_UBER",
      "me_car",
      "me_car-r_SwiftFleet",
      "me_mot",
      "cy_bic",
      "cy_bic-s",
      "wa_wal"
    ])
  }
  
}
