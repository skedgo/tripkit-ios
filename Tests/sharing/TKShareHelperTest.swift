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
  
  let geocoder: TKSkedGoGeocoder? = {
    let env = ProcessInfo.processInfo.environment
    if let apiKey = env["TRIPGO_API_KEY"], !apiKey.isEmpty {
      TripKit.apiKey = apiKey
      return TKSkedGoGeocoder()
    } else {
      return nil
    }
  }()
  
  func testQueryUrlWithW3W() throws {
    guard let geocoder = geocoder else {
      try XCTSkipIf(true, "Could not construct TKSkedGoGeocoder. Check environment variables.")
      return
    }

    let url = URL(string: "tripgo:///go?tname=dragon.letter.spoke")!
    
    guard let result = try TKShareHelper.queryDetails(for: url, using: geocoder).toBlocking().first() else { XCTFail(); return }
    
    XCTAssertNil(result.start)
    XCTAssertTrue(result.end.isValid)
    XCTAssertEqual(result.title, "dragon.letter.spoke")
    if case .leaveASAP = result.timeType {
      XCTAssertTrue(true)
    } else {
      XCTFail()
    }
    
  }

  func testW3WQueryUrlWithLatLng() throws {
    let geocoder = TKAppleGeocoder()
    let url = URL(string: "tripgo:///go?tlat=-33.94501&tlng=151.25807&type=1&time=1385535734")!
    
    guard let result = try TKShareHelper.queryDetails(for: url, using: geocoder).toBlocking().first() else { XCTFail(); return }
    
    XCTAssertNil(result.start)
    XCTAssertTrue(result.end.isValid)
    XCTAssertNil(result.title)
    XCTAssertEqual(result.end.latitude,  -33.94501, accuracy: 0.001)
    XCTAssertEqual(result.end.longitude, 151.25807, accuracy: 0.001)
    if case .leaveAfter(let time) = result.timeType {
      XCTAssertEqual(time.timeIntervalSince1970, 1385535734, accuracy: 1)
    } else {
      XCTFail()
    }
  }
  
  
  func testMeetUrl() throws {
    let geocoder = TKAppleGeocoder()
    let url = URL(string: "tripgo:///meet?lat=-33.94501&lng=151.25807&at=1385535734")!
    
    guard let result = try TKShareHelper.meetingDetails(for: url, using: geocoder).toBlocking().first() else { XCTFail(); return }
    
    XCTAssertNil(result.start)
    XCTAssertTrue(result.end.isValid)
    XCTAssertEqual(result.end.latitude,  -33.94501, accuracy: 0.001)
    XCTAssertEqual(result.end.longitude, 151.25807, accuracy: 0.001)
    
    if case .arriveBy(let time) = result.timeType {
      XCTAssertEqual(time.timeIntervalSince1970, 1385535734, accuracy: 1)
    } else {
      XCTFail()
    }
  }
  
  func testStopUrl() throws {
    let url = URL(string: "tripgo:///stop/AU_NSW_Sydney/2035143")!
    
    guard let result = try TKShareHelper.stopDetails(for: url).toBlocking().first() else { XCTFail(); return }
    
    XCTAssertEqual(result.region, "AU_NSW_Sydney")
    XCTAssertEqual(result.code, "2035143")
    XCTAssertNil(result.filter)
  }
  
  func testServiceUrl() throws {
    let url = URL(string: "https://tripgo.com/service/AR_B_BahiaBlanca/AR_B_BahiaBlanca-P517245/trip-517-V-01-032/1529321905")!
    
    guard let result = try TKShareHelper.serviceDetails(for: url).toBlocking().first() else { XCTFail(); return }
    
    XCTAssertEqual(result.region, "AR_B_BahiaBlanca")
    XCTAssertEqual(result.stopCode, "AR_B_BahiaBlanca-P517245")
    XCTAssertEqual(result.serviceID, "trip-517-V-01-032")
  }
  
  func testOldServiceUrl() throws {
    let url = URL(string: "https://tripgo.com/service?regionName=AU_NSW_Sydney&stopCode=2000352&serviceID=89-W.1290.120.60.K.8.52029766")!
    
    guard let result = try TKShareHelper.serviceDetails(for: url).toBlocking().first() else { XCTFail(); return }
    
    XCTAssertEqual(result.region, "AU_NSW_Sydney")
    XCTAssertEqual(result.stopCode, "2000352")
    XCTAssertEqual(result.serviceID, "89-W.1290.120.60.K.8.52029766")
  }
  
}
