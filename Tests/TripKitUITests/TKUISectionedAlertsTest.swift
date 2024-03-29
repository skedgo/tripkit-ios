//
//  TKUISectionedAlertsTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 26.03.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import XCTest

@testable import TripKit
@testable import TripKitUI

@MainActor
class TKUISectionedAlertsTest: XCTestCase {

  var response: TKBuzzInfoProvider.AlertsTransitResponse!
  
  override func setUp() {
    let decoder = JSONDecoder()
//    decoder.dateDecodingStrategy = .iso8601 // for v=13
    let data = try! dataFromJSON(named: "alertsTransit-melbourne")
    self.response = try! decoder.decode(TKBuzzInfoProvider.AlertsTransitResponse.self, from: data)
  }
  
  func testParsingAlerts() throws {
    XCTAssertNotNil(response)
    
    let routeIDs = response.alerts.reduce(into: Set<String>()) { acc, mapping in
      mapping.routes?.forEach { acc.insert($0.id) }
    }
    XCTAssertEqual(routeIDs.count, 158)
  }

  func testGroupingAlerts() throws {
    XCTAssertNotNil(response)
    
    let grouped = TKUISectionedAlertViewModel.groupAlertMappings(response.alerts)
    XCTAssertEqual(grouped.count, 6)
    
    for (mode, routes) in grouped {
      XCTAssertFalse(mode.title.isEmpty)
      XCTAssertFalse(routes.isEmpty)

      for routeAlerts in routes {
        XCTAssertFalse(routeAlerts.title.isEmpty)
        XCTAssertFalse(routeAlerts.alerts.isEmpty)
      }
    }
    
    let totalRoutes = grouped.reduce(0) { $0 + $1.value.count }
    XCTAssertEqual(totalRoutes, 158)
  }

}
