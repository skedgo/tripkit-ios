//
//  TKWaypointRouterTest.swift
//  TripGo
//
//  Created by Adrian Schoenig on 21/09/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import XCTest

import RxSwift
import RxBlocking

import SwiftyJSON

@testable import TripKit

class TKWaypointRouterTest: TKTestCase {
  
  func testGettingOnLate() {
    // Homesby to Rocks, walking to Waitara
    let trip = self.trip(fromFilename: "hornsbyToSkedGo", serviceFilename: "hornsbyToSkedGoService")
    
    let trainSegment = trip.segments()[2]
    let service = trainSegment.service()!
    
    let waitara = (service.visits?.first { $0.stop.name!.hasPrefix("Waitara") })!
    
    let builder = WaypointParasBuilder()
    let paras = builder.build(moving: trainSegment, to: waitara, atStart: true)
    XCTAssertNotNil(paras)
    
    let swifty = JSON(paras)
    XCTAssertEqual(swifty["segments"].count, 3)
    
    let walkJson = swifty["segments"][0]
    XCTAssertEqual(walkJson["modes"][0].string, "wa_wal")

    // There should be an end coordinate for the walk
    guard let firstEndRaw = walkJson["end"].string else { XCTFail(); return }
    guard let coordinate = SVKParserHelper.coordinate(forRequest: firstEndRaw) else { XCTFail(); return }

    // End location of walk should match Waitara, not Hornsby
    let endLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    let waitaraLocation = CLLocation(latitude: waitara.coordinate.latitude, longitude: waitara.coordinate.longitude)
    XCTAssertLessThan(endLocation.distance(from: waitaraLocation), 50)
    
    let trainJson = swifty["segments"][1]
    XCTAssertEqual(trainJson["modes"][0].string, "pt_pub")
    XCTAssertEqual(trainJson["serviceTripID"].string, service.code)
    XCTAssertEqual(trainJson["start"].string, waitara.stop.stopCode)
    XCTAssertEqualWithAccuracy(trainJson["startTime"].doubleValue, waitara.departure!.timeIntervalSince1970, accuracy: 0.1)
  }
  
  func testGettingOffEarly() {
    // Homesby to Rocks, walking from Milson's Point
    let trip = self.trip(fromFilename: "hornsbyToSkedGo", serviceFilename: "hornsbyToSkedGoService")
    
    let trainSegment = trip.segments()[2]
    let service = trainSegment.service()!
    
    let milsons = (service.visits?.first { $0.stop.name!.hasPrefix("Milson") })!
    
    let builder = WaypointParasBuilder()
    let paras = builder.build(moving: trainSegment, to: milsons, atStart: false)
    XCTAssertNotNil(paras)
    
    let swifty = JSON(paras)
    XCTAssertEqual(swifty["segments"].count, 3)
    
    let walkJson = swifty["segments"][2]
    XCTAssertEqual(walkJson["modes"][0].string, "wa_wal")
    
    // There should be an end coordinate for the walk
    guard let rawStart = walkJson["start"].string else { XCTFail(); return }
    guard let coordinate = SVKParserHelper.coordinate(forRequest: rawStart) else { XCTFail(); return }
    
    // Start location of walk should match Milson's Point, not Wynyard
    let startLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    let milsonsLocation = CLLocation(latitude: milsons.coordinate.latitude, longitude: milsons.coordinate.longitude)
    XCTAssertLessThan(startLocation.distance(from: milsonsLocation), 50)
    
    let trainJson = swifty["segments"][1]
    XCTAssertEqual(trainJson["modes"][0].string, "pt_pub")
    XCTAssertEqual(trainJson["serviceTripID"].string, service.code)
    XCTAssertEqual(trainJson["end"].string, milsons.stop.stopCode)
    XCTAssertEqualWithAccuracy(trainJson["endTime"].doubleValue, milsons.arrival!.timeIntervalSince1970, accuracy: 0.1)
  }
  
  func testAddingWalkAtStart() {
    // Berowra to Hornsby, hike to Mt Kuring-Gai
    let trip = self.trip(fromFilename: "berowraToHornsby", serviceFilename: "berowraToHornsbyService")
    
    let trainSegment = trip.segments()[1]
    let service = trainSegment.service()!
    
    let kuring = (service.visits?.first { $0.stop.name!.contains("Kuring") })!
    
    let builder = WaypointParasBuilder()
    let paras = builder.build(moving: trainSegment, to: kuring, atStart: true)
    XCTAssertNotNil(paras)
    
    let swifty = JSON(paras)
    XCTAssertEqual(swifty["segments"].count, 2)
    
    let walkJson = swifty["segments"][0]
    XCTAssertEqual(walkJson["modes"][0].string, "wa_wal")
    
    // Checking start of walk against trip
    guard let firstStartRaw = walkJson["start"].string else { XCTFail(); return }
    guard let firstStart = SVKParserHelper.coordinate(forRequest: firstStartRaw) else { XCTFail(); return }
    let startLocation = CLLocation(latitude: firstStart.latitude, longitude: firstStart.longitude)
    let tripStartLocation = CLLocation(latitude: trip.request.fromLocation.coordinate.latitude, longitude: trip.request.fromLocation.coordinate.longitude)
    XCTAssertLessThan(startLocation.distance(from: tripStartLocation), 50)

    // Checking end of walk against Mt Kuring-Gai
    guard let firstEndRaw = walkJson["end"].string else { XCTFail(); return }
    guard let firstEnd = SVKParserHelper.coordinate(forRequest: firstEndRaw) else { XCTFail(); return }
    let endLocation = CLLocation(latitude: firstEnd.latitude, longitude: firstEnd.longitude)
    let kuringLocation = CLLocation(latitude: kuring.coordinate.latitude, longitude: kuring.coordinate.longitude)
    XCTAssertLessThan(endLocation.distance(from: kuringLocation), 50)
    
    let trainJson = swifty["segments"][1]
    XCTAssertEqual(trainJson["modes"][0].string, "pt_pub")
    XCTAssertEqual(trainJson["serviceTripID"].string, service.code)
    XCTAssertEqual(trainJson["start"].string, kuring.stop.stopCode)
    XCTAssertEqualWithAccuracy(trainJson["startTime"].doubleValue, kuring.departure!.timeIntervalSince1970, accuracy: 0.1)
  }
  
  func testAddingWalkAtEnd() {
    // Berowra to Hornsby, hike from Asquith
    let trip = self.trip(fromFilename: "berowraToHornsby", serviceFilename: "berowraToHornsbyService")
    
    let trainSegment = trip.segments()[1]
    let service = trainSegment.service()!
    
    let asquith = (service.visits?.first { $0.stop.name!.contains("Asquith") })!
    
    let builder = WaypointParasBuilder()
    let paras = builder.build(moving: trainSegment, to: asquith, atStart: false)
    XCTAssertNotNil(paras)
    
    let swifty = JSON(paras)
    XCTAssertEqual(swifty["segments"].count, 2)
    
    let walkJson = swifty["segments"][1]
    XCTAssertEqual(walkJson["modes"][0].string, "wa_wal")
    
    // Checking start of walk against Asquith
    guard let firstStartRaw = walkJson["start"].string else { XCTFail(); return }
    guard let firstStart = SVKParserHelper.coordinate(forRequest: firstStartRaw) else { XCTFail(); return }
    let startLocation = CLLocation(latitude: firstStart.latitude, longitude: firstStart.longitude)
    let asquithLocation = CLLocation(latitude: asquith.coordinate.latitude, longitude: asquith.coordinate.longitude)
    XCTAssertLessThan(startLocation.distance(from: asquithLocation), 50)
    
    // Checking end of walk against trip
    guard let firstEndRaw = walkJson["end"].string else { XCTFail(); return }
    guard let firstEnd = SVKParserHelper.coordinate(forRequest: firstEndRaw) else { XCTFail(); return }
    let endLocation = CLLocation(latitude: firstEnd.latitude, longitude: firstEnd.longitude)
    let tripEndLocation = CLLocation(latitude: trip.request.toLocation.coordinate.latitude, longitude: trip.request.toLocation.coordinate.longitude)
    XCTAssertLessThan(endLocation.distance(from: tripEndLocation), 50)
    
    let trainJson = swifty["segments"][0]
    XCTAssertEqual(trainJson["modes"][0].string, "pt_pub")
    XCTAssertEqual(trainJson["serviceTripID"].string, service.code)
    XCTAssertEqual(trainJson["end"].string, asquith.stop.stopCode)
    XCTAssertEqualWithAccuracy(trainJson["endTime"].doubleValue, asquith.arrival!.timeIntervalSince1970, accuracy: 0.1)
  }

//  func testChangeTripWithTwoService() {
//    XCTFail()
//  }

//  func testChangeTripAfterServiceIdChange() {
//    XCTFail()
//  }

}
