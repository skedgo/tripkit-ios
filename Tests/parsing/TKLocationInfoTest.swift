//
//  TKLocationInfoTest.swift
//  TripKit
//
//  Created by Adrian Schoenig on 7/12/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import XCTest

@testable import TripKit

class TKLocationInfoTest: XCTestCase {
    
  func testLocationInformationForBikePods() throws {
    let decoder = JSONDecoder()
    let data = try dataFromJSON(named: "locationInfo-bikePod")
    let info = try decoder.decode(TKAPI.LocationInfo.self, from: data)
    
    // Basic info
    XCTAssertEqual(info.details?.w3w, "ruled.item.chart")
    
    // Bike pod info
    XCTAssertNotNil(info.bikePod)
    XCTAssertEqual(info.bikePod?.availableBikes, 9)
    XCTAssertEqual(info.bikePod?.availableSpaces, 1)
    XCTAssertEqual(info.bikePod?.operatorInfo.name, "Melbourne Bike Share")
    XCTAssertNotNil(info.bikePod?.source)
    XCTAssertEqual(info.bikePod?.source?.provider.name, "CityBikes")
  }
  

  func testCarRental() throws {
    let decoder = JSONDecoder()
    let data = try dataFromJSON(named: "locationInfo-carRental")
    let info = try! decoder.decode(TKAPI.LocationInfo.self, from: data)

    let MTZ = TimeZone(identifier: "Australia/Melbourne")!

    // Car rental info
    XCTAssertNotNil(info.carRental)
    XCTAssertEqual(info.carRental?.company.name, "East Coast Rentals")
    XCTAssertEqual(info.carRental?.source?.provider.name, "Swiftfleet")
    XCTAssertNotNil(info.carRental?.openingHours)
    XCTAssertEqual(info.carRental?.openingHours?.timeZone, MTZ)

    guard let hours = info.carRental?.openingHours else { XCTFail(); return }

    XCTAssertEqual(hours.isOpen(at: Date(from: "16-12-07 07:59", in: MTZ)), false)
    XCTAssertEqual(hours.isOpen(at: Date(from: "16-12-07 08:00", in: MTZ)), true)
    XCTAssertEqual(hours.isOpen(at: Date(from: "16-12-07 16:59", in: MTZ)), true)
    XCTAssertEqual(hours.isOpen(at: Date(from: "16-12-07 17:00", in: MTZ)), false)
  }
  
  func testCarRentalSpecialDays() throws {
    let decoder = JSONDecoder()
    let data = try dataFromJSON(named: "locationInfo-carRental-days")
    let info = try! decoder.decode(TKAPI.LocationInfo.self, from: data)
        
    guard let hours = info.carRental?.openingHours else { XCTFail(); return }
    XCTAssertEqual(hours.days.isEmpty, false)
  }

  func testOnStreetParking() throws {
    let decoder = JSONDecoder()
    let data = try dataFromJSON(named: "locationInfo-onStreetParking")
    let info = try! decoder.decode(TKAPI.LocationInfo.self, from: data)
    
    guard let parking = info.onStreetParking else { XCTFail(); return }
    XCTAssertNotNil(parking)
  }
}


extension Date {
  
  fileprivate init(from string: String, in timeZone: TimeZone) {
    let formatter = DateFormatter()
    formatter.dateFormat = "YY-MM-dd' 'HH:mm"
    formatter.timeZone = timeZone
    self = formatter.date(from: string)!
  }
  
}

