//
//  TKAlertModelTest.swift
//  TripKitTests
//
//  Created by Kuan Lun Huang on 27/10/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import XCTest
@testable import TripKit

class TKAlertModelTest: XCTestCase {
  
  var encoder: JSONEncoder!
  var decoder: JSONDecoder!
    
  override func setUp() {
    super.setUp()
    
    encoder = JSONEncoder()
    decoder = JSONDecoder()
  }
  
  override func tearDown() {
    encoder = nil
    decoder = nil
    super.tearDown()
  }
  
  // MARK: - Decoding
  
  func testAlertWithRerouteAction() throws {
    let json = """
        {
            "action": {
                "excludedStopCodes": [
                    "200060"
                ],
                "text": "Alternative routes",
                "type": "rerouteExcludingStops"
            },
            "hashCode": -2051420954,
            "severity": "warning",
            "stopCode": "200060",
            "text": "The escalator between the suburban and intercity platforms is temporarily out of service. If you require assistance, please ask staff or phone 9379 1777.",
            "title": "Escalator Availability - Central",
            "url": "http://www.transportnsw.info/transport-status"
        }
        """
    
    let model = try apiAlertModel(from: json)
    XCTAssertNotNil(model.action)
    XCTAssertEqual(String(describing: model.action!.type), String(describing: TKAPI.Alert.Action.ActionType.reroute(["200060"])))
  }
  
  func testRerouteActionWithoutStopsToAvoid() throws {
    let json = """
        {
            "action": {
                "text": "Alternative routes",
                "type": "rerouteExcludingStops"
            },
            "hashCode": -2051420954,
            "severity": "warning",
            "stopCode": "200060",
            "text": "The escalator between the suburban and intercity platforms is temporarily out of service. If you require assistance, please ask staff or phone 9379 1777.",
            "title": "Escalator Availability - Central",
            "url": "http://www.transportnsw.info/transport-status"
        }
        """
    
    let model = try apiAlertModel(from: json)
    XCTAssertNil(model.action)
  }
  
  func testAlertWithUnknownAction() throws {
    let json = """
        {
            "action": {
                "text": "Alternative routes",
                "type": "futureActionTypeToBeImplemented"
            },
            "hashCode": -2051420954,
            "severity": "warning",
            "stopCode": "200060",
            "text": "The escalator between the suburban and intercity platforms is temporarily out of service. If you require assistance, please ask staff or phone 9379 1777.",
            "title": "Escalator Availability - Central",
            "url": "http://www.transportnsw.info/transport-status"
        }
        """
    
    let model = try apiAlertModel(from: json)
    XCTAssertNil(model.action)
  }
  
  func testAlertWithoutAction() throws {
    let json = """
        {
            "hashCode": 1547928980,
            "serviceTripID": "211J.1513.100.120.H.8.47431931",
            "severity": "warning",
            "text": "Strathfield due to a freight train with mechanical problems at Hawkesbury River earlier.",
            "title": "Commencing from",
            "url": "http://www.sydneytrains.info/"
        }
        """
    
    let model = try apiAlertModel(from: json)
    XCTAssertNil(model.action)
  }
  
  // MARK: - Helper
  
  func apiAlertModel(from jsonString: String) throws -> TKAPI.Alert {
    let data = jsonString.data(using: .utf8)!
    return try decoder.decode(TKAPI.Alert.self, from: data)
  }
  
}
