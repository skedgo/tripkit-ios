//
//  TKAPIParsingTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 6/3/2023.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import XCTest

@testable import TripKit

final class TKAPIParsingTest: XCTestCase {
  
  func testParsingManlyWharf() throws {
    let parentStop = try JSONDecoder().decode(TKAPI.Stop.self, from: Data("""
      {
        "lat": -33.80055,
        "lng": 151.28428,
        "timezone": "Australia/Sydney",
        "city": "AU.NSW.Sydney",
        "address": "Manly Wharf",
        "region": "AU_NSW_Sydney",
        "id": "pt_pub|AU_NSW_Sydney|209573",
        "name": "Manly Wharf",
        "code": "209573",
        "popularity": 237,
        "services": "",
        "stopCode": "209573",
        "modeInfo": {
          "identifier": "pt_pub_ferry",
          "alt": "ferry",
          "localIcon": "ferry",
          "color": {
            "red": 1,
            "green": 162,
            "blue": 86
          }
        },
        "children": [
          {
            "lat": -33.80058,
            "lng": 151.28461,
            "timezone": "Australia/Sydney",
            "city": "AU.NSW.Sydney",
            "address": "Manly, Wharf 3",
            "region": "AU_NSW_Sydney",
            "id": "pt_pub|AU_NSW_Sydney|209593",
            "name": "Manly, Wharf 3",
            "code": "209593",
            "popularity": 33,
            "services": "",
            "stopCode": "209593",
            "modeInfo": {
              "identifier": "pt_pub_ferry",
              "alt": "ferry",
              "localIcon": "ferry",
              "color": {
                "red": 1,
                "green": 162,
                "blue": 86
              }
            },
            "wheelchairAccessible": false,
            "shortName": "3",
            "platformCode": "3",
            "publicTransportMode": "pt_pub_ferry",
            "stopType": "ferry",
            "class": "StopLocation"
          },
          {
            "lat": -33.80051,
            "lng": 151.28395,
            "timezone": "Australia/Sydney",
            "city": "AU.NSW.Sydney",
            "address": "Manly, Wharf 2",
            "region": "AU_NSW_Sydney",
            "id": "pt_pub|AU_NSW_Sydney|209525",
            "name": "Manly, Wharf 2",
            "code": "209525",
            "popularity": 204,
            "services": "",
            "stopCode": "209525",
            "modeInfo": {
              "identifier": "pt_pub_ferry",
              "alt": "ferry",
              "localIcon": "ferry",
              "color": {
                "red": 1,
                "green": 162,
                "blue": 86
              }
            },
            "wheelchairAccessible": true,
            "shortName": "2",
            "platformCode": "2",
            "publicTransportMode": "pt_pub_ferry",
            "stopType": "ferry",
            "class": "StopLocation"
          }
        ],
        "publicTransportMode": "pt_pub_ferry",
        "stopType": "ferry",
        "class": "StopLocation"
      }
    """.utf8))
    
    let parentCoordinate = TKStopCoordinate(parentStop)
    XCTAssertEqual(parentCoordinate.wheelchairAccessibility, .unknown)
    
    let platform3 = try XCTUnwrap(parentStop.children.first)
    XCTAssertEqual(TKStopCoordinate(platform3).wheelchairAccessibility, .notAccessible)

    let platform2 = try XCTUnwrap(parentStop.children.last)
    XCTAssertEqual(TKStopCoordinate(platform2).wheelchairAccessibility, .accessible)
  }
  
  
}
