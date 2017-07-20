//
//  TKShareHelperTest.swift
//  TripKit
//
//  Created by Adrian Schoenig on 29/08/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import XCTest

import RxBlocking

@testable import TripKit

class TKShareHelperTest: XCTestCase {
  
  func testQueryUrlWithW3W() {
    let geocoder = SGBuzzGeocoder()
    let url = URL(string: "tripgo:///go?tname=dragon.letter.spoke")!
    
    guard let w = try? TKSwiftyShareHelper.queryDetails(for: url, using: geocoder).toBlocking().first(), let result = w else { XCTFail(); return }
    
    XCTAssertNil(result.start)
    XCTAssertTrue(result.end.isValid)
    XCTAssertEqual(result.title, "dragon.letter.spoke")
    if case .leaveASAP = result.timeType {
      XCTAssertTrue(true)
    } else {
      XCTFail()
    }
    
  }

  func testW3WQueryUrlWithLatLng() {
    let geocoder = SGBuzzGeocoder()
    let url = URL(string: "tripgo:///go?tlat=-33.94501&tlng=151.25807&type=1&time=1385535734")!
    
    guard let w = try? TKSwiftyShareHelper.queryDetails(for: url, using: geocoder).toBlocking().first(), let result = w else { XCTFail(); return }
    
    XCTAssertNil(result.start)
    XCTAssertTrue(result.end.isValid)
    XCTAssertNil(result.title)
    XCTAssertEqualWithAccuracy(result.end.latitude,  -33.94501, accuracy: 0.001)
    XCTAssertEqualWithAccuracy(result.end.longitude, 151.25807, accuracy: 0.001)
    if case .leaveAfter(let time) = result.timeType {
      XCTAssertEqualWithAccuracy(time.timeIntervalSince1970, 1385535734, accuracy: 1)
    } else {
      XCTFail()
    }
  }
  
  
  func testMeetUrl() {
    let geocoder = SGAppleGeocoder()
    let url = URL(string: "tripgo:///meet?lat=-33.94501&lng=151.25807&at=1385535734")!
    
    guard let w = try? TKSwiftyShareHelper.meetingDetails(for: url, using: geocoder).toBlocking().first(), let result = w else { XCTFail(); return }
    
    XCTAssertNil(result.start)
    XCTAssertTrue(result.end.isValid)
    XCTAssertEqualWithAccuracy(result.end.latitude,  -33.94501, accuracy: 0.001)
    XCTAssertEqualWithAccuracy(result.end.longitude, 151.25807, accuracy: 0.001)
    
    if case .arriveBy(let time) = result.timeType {
      XCTAssertEqualWithAccuracy(time.timeIntervalSince1970, 1385535734, accuracy: 1)
    } else {
      XCTFail()
    }
  }
  
  func testStopUrl() {
    let url = URL(string: "tripgo:///stop/AU_NSW_Sydney/2035143")!
    
    guard let w = try? TKSwiftyShareHelper.stopDetails(for: url).toBlocking().first(), let result = w else { XCTFail(); return }
    
    XCTAssertEqual(result.region, "AU_NSW_Sydney")
    XCTAssertEqual(result.code, "2035143")
    XCTAssertNil(result.filter)
  }
  
}
