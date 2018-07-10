//
//  TKWaypointRouterTest.swift
//  TripKit
//
//  Created by Adrian Schoenig on 21/09/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import XCTest

import RxSwift
import RxBlocking

@testable import TripKit

class TKWaypointRouterTest: TKTestCase {
  
  private let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970
    return decoder
  }()
  
  func testGettingOnLate() throws {
    // Homesby to Rocks, walking to Waitara
    let trip = self.trip(fromFilename: "hornsbyToSkedGo", serviceFilename: "hornsbyToSkedGoService")
    
    let trainSegment = trip.segments()[2]
    let service = trainSegment.service()!
    
    let waitara = (service.visits?.first { $0.stop.name!.hasPrefix("Waitara") })!
    
    let builder = WaypointParasBuilder()
    let paras = builder.build(moving: trainSegment, to: waitara, atStart: true)
    XCTAssertNotNil(paras)
    
    let input = try decoder.decode(WaypointInput.self, withJSONObject: paras)
    XCTAssertEqual(input.segments.count, 3)
    
    let walkInput = input.segments[0]
    XCTAssertEqual(walkInput.modes, ["wa_wal"])

    // There should be an end coordinate for the walk
    guard let coordinate = walkInput.endCoordinate else { XCTFail(); return }

    // End location of walk should match Waitara, not Hornsby
    let endLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    let waitaraLocation = CLLocation(latitude: waitara.coordinate.latitude, longitude: waitara.coordinate.longitude)
    XCTAssertLessThan(endLocation.distance(from: waitaraLocation), 50)
    
    let trainJson = input.segments[1]
    XCTAssertEqual(trainJson.modes, ["pt_pub"])
    XCTAssertEqual(trainJson.serviceTripID, service.code)
    XCTAssertEqual(trainJson.start, waitara.stop.stopCode)
    XCTAssertEqual(trainJson.startTime!.timeIntervalSince1970, waitara.departure!.timeIntervalSince1970, accuracy: 0.1)
  }
  
  func testGettingOffEarly() throws {
    // Homesby to Rocks, walking from Milson's Point
    let trip = self.trip(fromFilename: "hornsbyToSkedGo", serviceFilename: "hornsbyToSkedGoService")
    
    let trainSegment = trip.segments()[2]
    let service = trainSegment.service()!
    
    let milsons = (service.visits?.first { $0.stop.name!.hasPrefix("Milson") })!
    
    let builder = WaypointParasBuilder()
    let paras = builder.build(moving: trainSegment, to: milsons, atStart: false)
    XCTAssertNotNil(paras)
    
    let input = try decoder.decode(WaypointInput.self, withJSONObject: paras)
    XCTAssertEqual(input.segments.count, 3)
    
    let walkInput = input.segments[2]
    XCTAssertEqual(walkInput.modes, ["wa_wal"])
    
    // There should be a start coordinate for the walk
    guard let coordinate = walkInput.startCoordinate else { XCTFail(); return }
    
    // Start location of walk should match Milson's Point, not Wynyard
    let startLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    let milsonsLocation = CLLocation(latitude: milsons.coordinate.latitude, longitude: milsons.coordinate.longitude)
    XCTAssertLessThan(startLocation.distance(from: milsonsLocation), 50)
    
    let trainJson = input.segments[1]
    XCTAssertEqual(trainJson.modes, ["pt_pub"])
    XCTAssertEqual(trainJson.serviceTripID, service.code)
    XCTAssertEqual(trainJson.end, milsons.stop.stopCode)
    XCTAssertEqual(trainJson.endTime!.timeIntervalSince1970, milsons.arrival!.timeIntervalSince1970, accuracy: 0.1)
  }
  
  func testAddingWalkAtStart() throws {
    // Berowra to Hornsby, hike to Mt Kuring-Gai
    let trip = self.trip(fromFilename: "berowraToHornsby", serviceFilename: "berowraToHornsbyService")
    
    let trainSegment = trip.segments()[1]
    let service = trainSegment.service()!
    
    let kuring = (service.visits?.first { $0.stop.name!.contains("Kuring") })!
    
    let builder = WaypointParasBuilder()
    let paras = builder.build(moving: trainSegment, to: kuring, atStart: true)
    XCTAssertNotNil(paras)
    
    let input = try decoder.decode(WaypointInput.self, withJSONObject: paras)
    XCTAssertEqual(input.segments.count, 2)

    let walkInput = input.segments[0]
    XCTAssertEqual(walkInput.modes, ["wa_wal"])

    // Checking start of walk against trip
    guard let firstStart = walkInput.startCoordinate else { XCTFail(); return }
    let startLocation = CLLocation(latitude: firstStart.latitude, longitude: firstStart.longitude)
    let tripStartLocation = CLLocation(latitude: trip.request.fromLocation.coordinate.latitude, longitude: trip.request.fromLocation.coordinate.longitude)
    XCTAssertLessThan(startLocation.distance(from: tripStartLocation), 50)

    // Checking end of walk against Mt Kuring-Gai
    guard let firstEnd = walkInput.endCoordinate else { XCTFail(); return }
    let endLocation = CLLocation(latitude: firstEnd.latitude, longitude: firstEnd.longitude)
    let kuringLocation = CLLocation(latitude: kuring.coordinate.latitude, longitude: kuring.coordinate.longitude)
    XCTAssertLessThan(endLocation.distance(from: kuringLocation), 50)
    
    let trainJson = input.segments[1]
    XCTAssertEqual(trainJson.modes, ["pt_pub"])
    XCTAssertEqual(trainJson.serviceTripID, service.code)
    XCTAssertEqual(trainJson.start, kuring.stop.stopCode)
    XCTAssertEqual(trainJson.startTime!.timeIntervalSince1970, kuring.departure!.timeIntervalSince1970, accuracy: 0.1)
  }
  
  func testAddingWalkAtEnd() throws {
    // Berowra to Hornsby, hike from Asquith
    let trip = self.trip(fromFilename: "berowraToHornsby", serviceFilename: "berowraToHornsbyService")
    
    let trainSegment = trip.segments()[1]
    let service = trainSegment.service()!
    
    let asquith = (service.visits?.first { $0.stop.name!.contains("Asquith") })!
    
    let builder = WaypointParasBuilder()
    let paras = builder.build(moving: trainSegment, to: asquith, atStart: false)
    XCTAssertNotNil(paras)
    
    let input = try decoder.decode(WaypointInput.self, withJSONObject: paras)
    XCTAssertEqual(input.segments.count, 2)
    
    let walkInput = input.segments[1]
    XCTAssertEqual(walkInput.modes, ["wa_wal"])

    // Checking start of walk against Asquith
    guard let firstStart = walkInput.startCoordinate else { XCTFail(); return }
    let startLocation = CLLocation(latitude: firstStart.latitude, longitude: firstStart.longitude)
    let asquithLocation = CLLocation(latitude: asquith.coordinate.latitude, longitude: asquith.coordinate.longitude)
    XCTAssertLessThan(startLocation.distance(from: asquithLocation), 50)
    
    // Checking end of walk against trip
    guard let firstEnd = walkInput.endCoordinate else { XCTFail(); return }
    let endLocation = CLLocation(latitude: firstEnd.latitude, longitude: firstEnd.longitude)
    let tripEndLocation = CLLocation(latitude: trip.request.toLocation.coordinate.latitude, longitude: trip.request.toLocation.coordinate.longitude)
    XCTAssertLessThan(endLocation.distance(from: tripEndLocation), 50)
    
    let trainJson = input.segments[0]
    XCTAssertEqual(trainJson.modes, ["pt_pub"])
    XCTAssertEqual(trainJson.serviceTripID, service.code)
    XCTAssertEqual(trainJson.end, asquith.stop.stopCode)
    XCTAssertEqual(trainJson.endTime!.timeIntervalSince1970, asquith.arrival!.timeIntervalSince1970, accuracy: 0.1)
  }
  
  func testChangingEmbarkationWhenDriving() throws {
    let trip = self.trip(fromFilename: "routing-drive-park-walk-train", serviceFilename: "service-for-park-ride")
    // start - drive - park - walk - train - walk - transfer - bus - walk - end
    
    let trainSegment = trip.segments()[4]
    let service = trainSegment.service()!
    
    let waitara = (service.visits?.first { $0.stop.name!.contains("Waitara") })!
    
    let builder = WaypointParasBuilder()
    let paras = builder.build(moving: trainSegment, to: waitara, atStart: true)
    XCTAssertNotNil(paras)

    let input = try decoder.decode(WaypointInput.self, withJSONObject: paras)
    XCTAssertEqual(input.segments.count, 5)
    
    let driveInput = input.segments[0]
    XCTAssertEqual(driveInput.modes, ["me_car"])
    
    let afterDrive = input.segments[1]
    XCTAssertEqual(afterDrive.modes, ["pt_pub"])
    
    guard let driveEnd = driveInput.endCoordinate else { XCTFail(); return }
    let endLocation = CLLocation(latitude: driveEnd.latitude, longitude: driveEnd.longitude)
    let waitaraLocation = CLLocation(latitude: waitara.coordinate.latitude, longitude: waitara.coordinate.longitude)
    XCTAssertLessThan(endLocation.distance(from: waitaraLocation), 50)


  }

//  func testChangeTripWithTwoService() {
//    XCTFail()
//  }

//  func testChangeTripAfterServiceIdChange() {
//    XCTFail()
//  }

}

// MARK: -

struct WaypointInput: Codable {
  
  let segments: [Segment]
  
  // Also:
  // - "config" => TKSettings
  // - "vehicles" => TKAPIToCoreDataConverter.vehiclesPayload

  struct Segment: Codable {
    // MARK: Required
    
    var start: String
    var end: String
    let modes: [String]
    
    // MARK: Optional
    
    let vehicleUUID: String?
    let serviceTripID: String?
    let `operator`: String?
    let region: String?
    let disembarkationRegion: String?
    let startTime: Date?
    let endTime: Date?
    
    // MARK: Helpers

    var startCoordinate: CLLocationCoordinate2D? {
      get {
        return TKParserHelper.coordinate(forRequest: start)
      }
      set {
        guard let newValue = newValue else { preconditionFailure("Set start directly, e.g., to a stop code") }
        start = TKParserHelper.requestString(for: newValue)
      }
    }
    
    var endCoordinate: CLLocationCoordinate2D? {
      get {
        return TKParserHelper.coordinate(forRequest: end)
      }
      set {
        guard let newValue = newValue else { preconditionFailure("Set end directly, e.g., to a stop code") }
        end = TKParserHelper.requestString(for: newValue)
      }
    }
  }
  
}

