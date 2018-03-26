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

@available(iOS 10.0, *)
class TKSectionedAlertsTest: TKTestCase {

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

  @available(iOS 10.0, *)
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
  }

}
