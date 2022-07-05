//
//  TKWaypointRouterTest.swift
//  TripKit
//
//  Created by Adrian Schoenig on 21/09/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import XCTest
import CoreLocation

@testable import TripKit

class TKWaypointRouterTest: TKTestCase {
  
  private let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970
    return decoder
  }()
  
  func testGettingOnLate() throws {
    // Homesby to Rocks, walking to Waitara
    let trip = try self.trip(fromFilename: "hornsbyToSkedGo", serviceFilename: "hornsbyToSkedGoService")
    
    let trainSegment = trip.segments[2]
    let service = trainSegment.service!
    
    let waitara = (service.visits?.first { $0.stop.name!.hasPrefix("Waitara") })!
    
    let segments = try TKWaypointRouter.segments(moving: trainSegment, to: waitara, atStart: true)
    XCTAssertEqual(segments.count, 3)
    
    let walkInput = segments[0]
    XCTAssertEqual(walkInput.modes, ["wa_wal"])

    // There should be an end coordinate for the walk
    guard case .coordinate(let endCoordinate) = walkInput.end else { return XCTFail() }

    // End location of walk should match Waitara, not Hornsby
    XCTAssertLessThan(endCoordinate.distance(from: waitara.coordinate)!, 50)
    
    let trainInput = segments[1]
    guard case .code(let startStopCode, _) = trainInput.start else { return XCTFail() }
    XCTAssertEqual(trainInput.modes, ["pt_pub"])
    XCTAssertEqual(trainInput.serviceTripID, service.code)
    XCTAssertEqual(startStopCode, waitara.stop.stopCode)
    XCTAssertEqual(trainInput.startTime!.timeIntervalSince1970, waitara.departure!.timeIntervalSince1970, accuracy: 0.1)
  }
  
  func testGettingOffEarly() throws {
    // Homesby to Rocks, walking from Milson's Point
    let trip = try self.trip(fromFilename: "hornsbyToSkedGo", serviceFilename: "hornsbyToSkedGoService")
    
    let trainSegment = trip.segments[2]
    let service = trainSegment.service!
    
    let milsons = (service.visits?.first { $0.stop.name!.hasPrefix("Milson") })!
    
    let segments = try TKWaypointRouter.segments(moving: trainSegment, to: milsons, atStart: false)
    XCTAssertEqual(segments.count, 3)
    
    let walkInput = segments[2]
    XCTAssertEqual(walkInput.modes, ["wa_wal"])
    
    // There should be a start coordinate for the walk
    guard case .coordinate(let startCoordinate) = walkInput.start else { return XCTFail() }

    // Start location of walk should match Milson's Point, not Wynyard
    XCTAssertLessThan(startCoordinate.distance(from: milsons.coordinate)!, 50)
    
    let trainInput = segments[1]
    guard case .code(let endStopCode, _) = trainInput.end else { return XCTFail() }
    XCTAssertEqual(trainInput.modes, ["pt_pub"])
    XCTAssertEqual(trainInput.serviceTripID, service.code)
    XCTAssertEqual(endStopCode, milsons.stop.stopCode)
    XCTAssertEqual(trainInput.endTime!.timeIntervalSince1970, milsons.arrival!.timeIntervalSince1970, accuracy: 0.1)
  }
  
  func testAddingWalkAtStart() throws {
    // Berowra to Hornsby, hike to Mt Kuring-Gai
    let trip = try self.trip(fromFilename: "berowraToHornsby", serviceFilename: "berowraToHornsbyService")
    
    let trainSegment = trip.segments[1]
    let service = trainSegment.service!
    
    let kuring = (service.visits?.first { $0.stop.name!.contains("Kuring") })!
    
    let segments = try TKWaypointRouter.segments(moving: trainSegment, to: kuring, atStart: true)
    XCTAssertEqual(segments.count, 2)

    let walkInput = segments[0]
    XCTAssertEqual(walkInput.modes, ["wa_wal"])

    // Checking start of walk against trip
    guard case .coordinate(let startCoordinate) = walkInput.start else { return XCTFail() }
    XCTAssertLessThan(startCoordinate.distance(from: trip.request.fromLocation.coordinate)!, 50)

    // Checking end of walk against Mt Kuring-Gai
    guard case .coordinate(let endCoordinate) = walkInput.end else { return XCTFail() }
    XCTAssertLessThan(endCoordinate.distance(from: kuring.coordinate)!, 50)
    
    let trainInput = segments[1]
    guard case .code(let startStopCode, _) = trainInput.start else { return XCTFail() }
    XCTAssertEqual(trainInput.modes, ["pt_pub"])
    XCTAssertEqual(trainInput.serviceTripID, service.code)
    XCTAssertEqual(startStopCode, kuring.stop.stopCode)
    XCTAssertEqual(trainInput.startTime!.timeIntervalSince1970, kuring.departure!.timeIntervalSince1970, accuracy: 0.1)
  }
  
  func testAddingWalkAtEnd() throws {
    // Berowra to Hornsby, hike from Asquith
    let trip = try self.trip(fromFilename: "berowraToHornsby", serviceFilename: "berowraToHornsbyService")
    
    let trainSegment = trip.segments[1]
    let service = trainSegment.service!
    
    let asquith = try XCTUnwrap(service.visits?.first { $0.stop.name!.contains("Asquith") })
    
    let segments = try TKWaypointRouter.segments(moving: trainSegment, to: asquith, atStart: false)
    XCTAssertEqual(segments.count, 2)
    
    let walkInput = segments[1]
    XCTAssertEqual(walkInput.modes, ["wa_wal"])

    // Checking start of walk against Asquith
    guard case .coordinate(let startCoordinate) = walkInput.start else { return XCTFail() }
    XCTAssertLessThan(startCoordinate.distance(from: asquith.coordinate)!, 50)
    
    // Checking end of walk against trip
    guard case .coordinate(let endCoordinate) = walkInput.end else { return XCTFail() }
    XCTAssertLessThan(endCoordinate.distance(from: trip.request.toLocation.coordinate)!, 50)
    
    let trainInput = segments[0]
    guard case .code(let endStopCode, _) = trainInput.end else { return XCTFail() }
    XCTAssertEqual(trainInput.modes, ["pt_pub"])
    XCTAssertEqual(trainInput.serviceTripID, service.code)
    XCTAssertEqual(endStopCode, asquith.stop.stopCode)
    XCTAssertEqual(trainInput.endTime!.timeIntervalSince1970, asquith.arrival!.timeIntervalSince1970, accuracy: 0.1)
  }
  
  func testChangingEmbarkationWhenDriving() throws {
    let trip = try self.trip(fromFilename: "routing-drive-park-walk-train", serviceFilename: "service-for-park-ride")
    // start - drive - park - walk - train - walk - transfer - bus - walk - end
    
    let trainSegment = trip.segments[4]
    let service = trainSegment.service!
    
    let waitara = (service.visits?.first { $0.stop.name!.contains("Waitara") })!
    
    let segments = try TKWaypointRouter.segments(moving: trainSegment, to: waitara, atStart: true)
    XCTAssertEqual(segments.count, 5)
    
    let driveInput = segments[0]
    XCTAssertEqual(driveInput.modes, ["me_car"])
    
    let afterDrive = segments[1]
    XCTAssertEqual(afterDrive.modes, ["pt_pub"])
    
    guard case .coordinate(let endCoordinate) = driveInput.end else { return XCTFail() }
    XCTAssertLessThan(endCoordinate.distance(from: waitara.coordinate)!, 50)
  }
  
  func testChangingParkWhenDrivingGoGet() throws {
    let trip = try self.trip(fromFilename: "routing-goget-park")
    // collect - GoGet - find parking
    
    let driveGoGetSegment = trip.segments[1]
    XCTAssertEqual(driveGoGetSegment.modeIdentifier, "me_car-s_GOG")
    
    let parkingData = try dataFromJSON(named: "location-carParks")
    let parking = try decoder.decode(TKCarParkLocation.self, from: parkingData)
    
    let segments = try TKWaypointRouter.segments(movingEndOf: driveGoGetSegment, to: parking)
    XCTAssertEqual(segments.count, 3)
    
    let beforeDrive = segments[0]
    XCTAssertEqual(beforeDrive.modes, ["wa_wal"])
    
    let drive = segments[1]
    XCTAssertEqual(drive.modes, ["me_car-s_GOG"])
    
    let afterDrive = segments[2]
    XCTAssertEqual(afterDrive.modes, ["wa_wal"])
    
    guard case .coordinate(let endCoordinate) = drive.end else { return XCTFail() }
    XCTAssertLessThan(endCoordinate.distance(from: parking.coordinate)!, 50)
  }
  
  func testChangingVehicleWhenDrivingGoGet() throws {
    let trip = try self.trip(fromFilename: "routing-goget-park")
    // collect - GoGet - find parking
    
    let driveGoGetSegment = trip.segments[1]
    XCTAssertEqual(driveGoGetSegment.modeIdentifier, "me_car-s_GOG")
    
    let vehicleData = try dataFromJSON(named: "location-carPods")
    let vehicle = try decoder.decode(TKCarPodLocation.self, from: vehicleData)
    
    let segments = try TKWaypointRouter.segments(movingStartOf: driveGoGetSegment, to: vehicle)
    XCTAssertEqual(segments.count, 3)
    
    let beforeDrive = segments[0]
    XCTAssertEqual(beforeDrive.modes, ["wa_wal"])
    
    let drive = segments[1]
    XCTAssertEqual(drive.modes, ["me_car-s_GOG"])
    
    let afterDrive = segments[2]
    XCTAssertEqual(afterDrive.modes, ["wa_wal"])
    
    guard case .coordinate(let startCoordinate) = drive.start else { return XCTFail() }
    XCTAssertLessThan(startCoordinate.distance(from: vehicle.coordinate)!, 50)
  }

}
