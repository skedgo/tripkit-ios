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
    let decoder = JSONDecoder()
    guard let data = dataFromJSON(named: "regionInfo-Sydney") else {
      XCTFail(); return
    }
    
    do {
      let response = try decoder.decode(TKBuzzInfoProvider.RegionInfoResponse.self, from: data)
      let sydney = response.regions.first

      XCTAssertEqual(response.regions.count, 1)
      
      XCTAssertNil(sydney?.paratransit)
      XCTAssertEqual(sydney?.streetBicyclePaths, true)
      XCTAssertEqual(sydney?.streetWheelchairAccessibility, true)
      XCTAssertEqual(sydney?.transitModes.count, 4)
      XCTAssertEqual(sydney?.transitBicycleAccessibility, true)
      XCTAssertEqual(sydney?.transitConcessionPricing, true)
      XCTAssertEqual(sydney?.transitWheelchairAccessibility, true)
    } catch {
      XCTFail("Failed with: \(error)")
    }
  }
  
  func testPublicTransportModes() {
    let decoder = JSONDecoder()
    guard let data = dataFromJSON(named: "regionInfo-Sydney") else {
      XCTFail(); return
    }
    
    do {
      let response = try decoder.decode(TKBuzzInfoProvider.RegionInfoResponse.self, from: data)
      let sydney = response.regions.first

      XCTAssertEqual(response.regions.count, 1)
      XCTAssertEqual(sydney?.transitModes.count, 4)
    } catch {
      XCTFail("Failed with: \(error)")
    }
  }
  
  func testTransitAlerts() {
    let decoder = JSONDecoder()
    guard let data = dataFromJSON(named: "alertsTransit") else {
      XCTFail(); return
    }
    
    do {
      let response = try decoder.decode(TKBuzzInfoProvider.AlertsTransitResponse.self, from: data)
      let wrappers = response.alerts
      
      XCTAssertEqual(wrappers.count, 6)
      
      // many checks on first
      XCTAssertEqual(wrappers[0].alert.title, "Wharf Closed")
      XCTAssertEqual(wrappers[0].alert.text, "Garden Island Wharf Closed.")
      XCTAssertEqual(wrappers[0].alert.severity, .warning)
      XCTAssertNil(wrappers[0].alert.remoteIcon)
      XCTAssertNil(wrappers[0].alert.url)
      
      // additional checks on others
      XCTAssertEqual(wrappers[1].alert.url, URL(string: "http://www.transportnsw.info/transport-status"))

      
    } catch {
      XCTFail("Failed with: \(error)")
    }
  }
}
