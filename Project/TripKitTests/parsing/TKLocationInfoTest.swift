//
//  TKLocationInfoTest.swift
//  TripKit
//
//  Created by Adrian Schoenig on 7/12/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import XCTest

import Marshal

@testable import TripKit

class TKLocationInfoTest: TKTestCase {
    
  func testLocationInformationForBikePods() {
    guard
      let json = contentFromJSON(named: "locationInfo-bikePod") as? [String: Any],
      let info = try? TKLocationInfo(object: json) else { XCTFail(); return }
    
    // Basic info
    XCTAssertEqual(info.what3word, "ruled.item.chart")
    
    // Bike pod info
    XCTAssertNotNil(info.bikePodInfo)
    XCTAssertEqual(info.bikePodInfo?.availableBikes, 9)
    XCTAssertEqual(info.bikePodInfo?.availableSpaces, 1)
    XCTAssertEqual(info.bikePodInfo?.operatorInfo.name, "Melbourne Bike Share")
    XCTAssertNotNil(info.bikePodInfo?.source)
    XCTAssertEqual(info.bikePodInfo?.source?.provider.name, "CityBikes")
  }
  

  func testCarRentalInfo() {
    guard
      let json = contentFromJSON(named: "locationInfo-carRental") as? [String: Any],
      let info = try? TKLocationInfo(object: json) else { XCTFail(); return }
    
    let MTZ = TimeZone(identifier: "Australia/Melbourne")!

    // Car rental info
    XCTAssertNotNil(info.carRentalInfo)
    XCTAssertEqual(info.carRentalInfo?.company.name, "East Coast Rentals")
    XCTAssertEqual(info.carRentalInfo?.source?.provider.name, "Swiftfleet")
    XCTAssertNotNil(info.carRentalInfo?.openingHours)
    XCTAssertEqual(info.carRentalInfo?.openingHours?.timeZone, MTZ)
    XCTAssertEqual(info.carRentalInfo?.openingHours?.days().count, 7)
    
    guard let hours = info.carRentalInfo?.openingHours else { XCTFail(); return }
    
    // Opening hour sorting
    XCTAssertEqual(hours.days(starting: .monday).first?.day.rawValue, "MONDAY")
    XCTAssertEqual(hours.days(starting: .monday).last?.day.rawValue, "SUNDAY")
    XCTAssertEqual(hours.days(starting: .sunday).first?.day.rawValue, "SUNDAY")
    XCTAssertEqual(hours.days(starting: .sunday).last?.day.rawValue, "SATURDAY")
    
    // Opening hour logic
    guard let aMonday = hours.days(starting: .monday).first else { XCTFail(); return }
    XCTAssertEqual(aMonday.contains(Date(from: "16-12-04 23:59", in: MTZ), in: MTZ), false)
    XCTAssertEqual(aMonday.contains(Date(from: "16-12-05 00:00", in: MTZ), in: MTZ), true)
    XCTAssertEqual(aMonday.contains(Date(from: "16-12-05 23:59", in: MTZ), in: MTZ), true)
    XCTAssertEqual(aMonday.contains(Date(from: "16-12-06 00:01", in: MTZ), in: MTZ), false)
    
    XCTAssertEqual(hours.isOpen(at: Date(from: "16-12-07 07:59", in: MTZ)), false)
    XCTAssertEqual(hours.isOpen(at: Date(from: "16-12-07 08:00", in: MTZ)), true)
    XCTAssertEqual(hours.isOpen(at: Date(from: "16-12-07 16:59", in: MTZ)), true)
    XCTAssertEqual(hours.isOpen(at: Date(from: "16-12-07 17:00", in: MTZ)), false)
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

