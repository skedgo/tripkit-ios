//
//  TKSectionedAlertsTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 26.03.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import XCTest

@testable import TripKit
@testable import TripKitUI

class TKSectionedAlertsTest: XCTestCase {

  var response: TKBuzzInfoProvider.AlertsTransitResponse!
  
  override func setUp() {
    let decoder = JSONDecoder()
//    decoder.dateDecodingStrategy = .iso8601 // for v=13
    let data = try! dataFromJSON(named: "alertsTransit-melbourne")
    self.response = try! decoder.decode(TKBuzzInfoProvider.AlertsTransitResponse.self, from: data)
  }
  
  func testParsingAlerts() throws {
    XCTAssertNotNil(response)
  }

  func testGroupingAlerts() throws {
    XCTAssertNotNil(response)
    
    let grouped = TKSectionedAlertViewModel.groupAlertMappings(response.alerts)
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
    XCTAssertEqual(totalRoutes, 159)
  }

}
