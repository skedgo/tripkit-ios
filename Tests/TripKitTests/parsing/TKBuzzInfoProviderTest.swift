//
//  TKBuzzInfoProviderTest.swift
//  TripKit
//
//  Created by Adrian Schoenig on 28/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import XCTest

@testable import TripKit

class TKBuzzInfoProviderTest: XCTestCase {
    
  func testRegionInformationSydney() throws {
    let decoder = JSONDecoder()
    let data = try dataFromJSON(named: "regionInfo-Sydney")
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
  }
  
  func testRegionInformationList() throws {
    let decoder = JSONDecoder()
    let data = try dataFromJSON(named: "regionInfo-multi")
    let response = try! decoder.decode(TKBuzzInfoProvider.RegionInfoResponse.self, from: data)
    
    XCTAssertEqual(response.regions.count, 6)
  }
  
  func testRegionInformationVancouver() throws {
    let decoder = JSONDecoder()
    let data = try dataFromJSON(named: "regionInfo-Vancouver")
    let response = try! decoder.decode(TKBuzzInfoProvider.RegionInfoResponse.self, from: data)
    let vancouver = response.regions.first
    
    XCTAssertEqual(response.regions.count, 1)
    
    XCTAssertEqual(vancouver?.modes.count, 5)
    XCTAssertEqual(vancouver?.modes["me_car-s"]?.specificModes.count, 1)
    XCTAssertEqual(vancouver?.specificModeDetails(for: "me_car-s_MODO")?.minimumLocalCostForMembership, 1)

    let modo = vancouver?.modes["me_car-s"]?.specificModes.first
    XCTAssertEqual(modo?.minimumLocalCostForMembership, 1)
    XCTAssertEqual(modo?.integrations.contains(.realTime), true)
  }
  
  func testRegionInformationNuremberg() throws {
    let decoder = JSONDecoder()
    let data = try dataFromJSON(named: "regionInfo-Nuremberg")
    let response = try decoder.decode(TKBuzzInfoProvider.RegionInfoResponse.self, from: data)
    let nuremberg = response.regions.first
    
    XCTAssertEqual(response.regions.count, 1)
    
    XCTAssertEqual(nuremberg?.modes.count, 6)
    XCTAssertEqual(nuremberg?.modes["ps_tax"]?.lockedModes.count, 1)
    XCTAssertEqual(nuremberg?.modes["ps_tax"]?.lockedModes.first?.identifier, "ps_tax_MYDRIVER")
    
    let norisbike = nuremberg?.specificModeDetails(for: "cy_bic-s_norisbike-nurnberg")
    XCTAssertEqual(norisbike?.url, URL(string: "http://www.norisbike.de"))
    XCTAssertEqual(norisbike?.title, "NorisBike")
    XCTAssertEqual(norisbike?.minimumLocalCostForMembership, 0)
    XCTAssertEqual(norisbike?.integrations.count, 2)
  }
  
  func testPublicTransportModes() throws {
    let decoder = JSONDecoder()
    let data = try dataFromJSON(named: "regionInfo-Sydney")
    let response = try decoder.decode(TKBuzzInfoProvider.RegionInfoResponse.self, from: data)
    let sydney = response.regions.first

    XCTAssertEqual(response.regions.count, 1)
    XCTAssertEqual(sydney?.transitModes.count, 4)
  }
  
  func testTransitAlerts() throws {
    let decoder = JSONDecoder()
    let data = try dataFromJSON(named: "alertsTransit")
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
  }
  
  func testRoutesSF() throws {
    let decoder = JSONDecoder()
    let data = try dataFromJSON(named: "routes-sf")
    let routes = try decoder.decode([TKAPI.Route].self, from: data)
    
    XCTAssertEqual(routes.count, 539)
  }
}
