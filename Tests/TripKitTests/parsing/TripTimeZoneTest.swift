//
//  TripTimeZoneTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 27/11/2026.
//  Copyright © 2026 SkedGo Pty Ltd. All rights reserved.
//

import XCTest
import CoreLocation

@testable import TripKit

/// Trip and segment times need to be shown in the time zone that the routing
/// response states, rather than one inferred from the loaded regions, which
/// can be missing the trip's region and then fell back to the device's.
class TripTimeZoneTest: TKTestCase {

  func testTimesUseTimeZoneFromResponse() throws {
    // No region uses Eucla and no device is set to it, so neither a region
    // lookup nor the fallback to `.current` can produce it.
    let eucla = try XCTUnwrap(TimeZone(identifier: "Australia/Eucla"))
    let json = try String(decoding: dataFromJSON(named: "routing-pt-darwin"), as: UTF8.self)
      .replacingOccurrences(of: "Australia/Darwin", with: eucla.identifier)
    let response = try JSONDecoder().decode(TKAPI.RoutingResponse.self, from: Data(json.utf8))

    // Like `TKRouter`, add to a request whose endpoints have no time zone
    let request = TripRequest.insert(
      from: TKNamedCoordinate(coordinate: .init(latitude: -12.4789, longitude: 130.98686)),
      to: TKNamedCoordinate(coordinate: .init(latitude: -12.5474, longitude: 131.122982)),
      for: nil, timeType: .leaveASAP, into: tripKitContext
    )
    let added = expectation(description: "Trips added")
    var trips: [Trip] = []
    TKRoutingParser.add(response, to: request, merge: false) { result in
      trips = (try? result.get()) ?? []
      added.fulfill()
    }
    wait(for: [added], timeout: 5)

    XCTAssertEqual(trips.count, 14)
    for trip in trips {
      XCTAssertEqual(trip.departureTimeZone, eucla)
      XCTAssertEqual(trip.arrivalTimeZone, eucla)
      for segment in trip.segments {
        XCTAssertEqual(segment.timeZone, eucla, "Wrong time zone for \(segment.order) segment")
      }
    }
  }

}
